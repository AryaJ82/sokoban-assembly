# By: Arya Jafari
.data
character:  .word 0,0 # Blue

# Address in stack for the array and size of array
# How do I deallocate this?
.align 4
boxArray:    .word 0, 6
targetArray: .word 0, 6

randseed:       .word 15342, 0, 45194

toggle:     .byte 1


.globl main
.text



############ IMPORTANT ################
## There is occasionally an error where the screen/LEDs don't load properly.
## The screen should be surrounded by white LEDs at the borders, if you only
## see the upper portion of the screen and some random points in the middle, then there is an error with ripes.
## Please ctrl+x a section of code (doesn't matter which), save, paste it back in, and save again.
## This should fix the error. I can say with certainty that the code works on my machine
########################################

# Specific implementation details can be found in the documentation file and under the code section itself
# The enhancements I've implemented are:

# Category A: Increasing difficulty by increasing the number of boxes and targets.
# Implementation under <PLAYERUP> at line 494
# Category B: Improved random number generator
# For implementation and citation please check under rand

main:
    ##
    la a0, boxArray
    lw t0, 1(a0)
    sub sp, sp, t0 # sp address moved to top of array
    sw sp, 0(a0) # Base address of boxArray is now sp
    mv a1, sp 
    
    la a0, targetArray
    lw t0, 1(a0)
    sub sp, sp, t0 # sp address moved to top of array
    sw sp, 0(a0) # Base address of targetArray is now sp
    mv a1, sp 

    ##
    jal gameStart


    gameLoop:
        jal resetSwitch
        jal playerMovement
        
        la a0, targetArray
        lw s0, 0(a0)
        lw s1, 4(a0)
        TARGETDRAWLOOP:
        beqz s1, ENDTARGETDRAWLOOP
        li a0, 65280
        lw a1, 0(s0)
        lw a2, 4(s0)
        jal setLED
        addi s1, s1, -2
        addi s0, s0, 8
        j TARGETDRAWLOOP
        ENDTARGETDRAWLOOP:
            
        la a0, boxArray
        lw s0, 0(a0)
        lw s1, 4(a0)
        BOXDRAWLOOP:
        beqz s1, ENDBOXDRAWLOOP
        li a0, 16711680
        lw a1, 0(s0)
        lw a2, 4(s0)
        jal setLED
        addi s1, s1, -2
        addi s0, s0, 8
        j BOXDRAWLOOP
        ENDBOXDRAWLOOP:
        
        # Draw character
        la a3, character
        lw a1, 0(a3)
        lw a2, 4(a3) 
        li a0, 255
        jal setLED
               

    la t0, targetArray
    lw s0, 0(t0)
    lw s1, 4(t0)
   
    GoalCheckLoop:
		beqz s1, GoalCheckPassed
		lw s4, 0(s0)
		lw s5, 4(s0)


        la a0, boxArray
        lw a7, 4(a0)
        lw a0, 0(a0)
        MatchTargetBoxLoop:
            lw t4, 0(a0)
            lw t5, 4(a0)
        
            bne t4, s4, NoMatchCont
            bne t5, s5, NoMatchCont
                addi s0, s0, 8
				addi s1, s1, -2
				j GoalCheckLoop
				
            NoMatchCont:
				addi a0, a0, 8
				addi a7, a7, -2
				beqz a7, GoalCheckFailed
				j MatchTargetBoxLoop
				
        
		GoalCheckPassed:
			# All boxes on targets
			la t0, targetArray
			lw t1, 4(t0)
			addi t1, t1, 2
			sw t1, 4(t0)
			
			la t0, boxArray
			lw t1, 4(t0)
			addi t1, t1, 2
			sw t1, 4(t0)
			jal gameStart
		GoalCheckFailed:
        #
        jal pollSwitchB
        beqz a0, gameLoop
    endGame:

exit:
    jal clearScreen
    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---
# Feel free to use (or modify) them however you see fit

resetSwitch:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    jal pollSwitchA
    la t0, toggle
    lb t1, 0(t0)
    bne a0, t1,  NoReset
    jal gameStart
    la t0, toggle
    lb t1, 0(t0)
    xori t1, t1, 1
    sb t1, 0(t0)
    NoReset:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

gameStart:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    jal clearScreen
    jal boundaryInit

    la s0, character
    li a0, LED_MATRIX_0_WIDTH
    addi a0, a0, -2
    jal rand
    addi a0, a0, 1
    sw a0, 0(s0)
    li a0, LED_MATRIX_0_HEIGHT
    addi a0, a0, -2
    jal rand
    addi a0, a0, 1
    sw a0, 4(s0)

    la s6, character
    ## Target coordinates
    la t0, targetArray
    lw s0, 0(t0)
    lw s1, 4(t0)
    mv s2, s0
    TargetRandGenLoop:
        li a0, LED_MATRIX_0_WIDTH
        addi a0, a0, -2
        jal rand
        addi s4, a0, 1
        li a0, LED_MATRIX_0_HEIGHT
        addi a0, a0, -2
        jal rand
        addi s5, a0, 1
        
        lw t4, 0(s6)
        lw t5, 4(s6)
        bne t4, s4, NoTargetPlayerMatchCont
        bne t5, s5, NoTargetPlayerMatchCont
            j TargetRandGenLoop
        NoTargetPlayerMatchCont:
            
        mv a0, s0
        TargetMatchLoop:
            beq a0, s2, EndTargetMatchLoop
            lw t4, 0(a0)
            lw t5, 4(a0)
        
            bne t4, s4, NoTargetMatchCont
            bne t5, s5, NoTargetMatchCont
            
                j TargetRandGenLoop
            NoTargetMatchCont:
            addi a0, a0, 8
            j TargetMatchLoop
        EndTargetMatchLoop:
        sw s4, 0(s2)
        sw s5, 4(s2)
        
        addi s2, s2, 8
        addi s1, s1, -2
        bnez s1, TargetRandGenLoop
    
    #### Boxes coordinates
    la t0, boxArray
    lw s0, 0(t0)
    lw s1, 4(t0)
    mv s2, s0
    BoxRandGenLoop:
        li a0, LED_MATRIX_0_WIDTH
        addi a0, a0, -4
        jal rand
        addi s4, a0, 2
        li a0, LED_MATRIX_0_HEIGHT
        addi a0, a0, -4
        jal rand
        addi s5, a0, 2
        
        lw t4, 0(s6)
        lw t5, 4(s6)
        bne t4, s4, NoBoxPlayerMatchCont
        bne t5, s5, NoBoxPlayerMatchCont
            j BoxRandGenLoop
        NoBoxPlayerMatchCont:

        la a0, targetArray
        lw a7, 4(a0)
        lw a0, 0(a0)
        BoxTargetMatchLoop:
            lw t4, 0(a0)
            lw t5, 4(a0)
        
            bne t4, s4, NoBoxTargetMatchCont
            bne t5, s5, NoBoxTargetMatchCont
            
                j BoxRandGenLoop
            NoBoxTargetMatchCont:
            addi a0, a0, 8
            addi a7, a7, -2
            bnez a7, BoxTargetMatchLoop
        
        
        mv a0, s0
        BoxMatchLoop:
            beq a0, s2, EndBoxMatchLoop
            lw t4, 0(a0)
            lw t5, 4(a0)
        
            bne t4, s4, NoBoxMatchCont
            bne t5, s5, NoBoxMatchCont
            
            j BoxRandGenLoop
            NoBoxMatchCont:
            addi a0, a0, 8
            j BoxMatchLoop
        EndBoxMatchLoop:
        
        sw s4, 0(s2)
        sw s5, 4(s2)
        
        addi s2, s2, 8
        addi s1, s1, -2
        bnez s1, BoxRandGenLoop

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra   
# Handles player movement inputs from dpad
playerMovement:
	addi sp, sp -4
	sw ra, 0(sp)
	jal pollDpad
    la a3, character
    lw a1, 0(a3)
    lw a2, 4(a3)

    la t0, boxArray
    lw s0, 0(t0)
    lw s1, 4(t0)


    mv t0, x0
    mv s7, x0

    beq a0, t0, PLAYERUP
    addi t0, t0, 1
    beq a0, t0, PLAYERDOWN
    addi t0, t0, 1
    beq a0, t0, PLAYERLEFT
    addi t0, t0, 1
    beq a0, t0, PLAYERRIGHT
    
    # Branches are at the very bottom of document

    j MOVEMENTDONE
    
    MOVEMENTDONE:
    slli s7, s7, 2
    add sp, sp, s7
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


# Draws the boundary LEDs. Does not preserve s registers. Assumes screen is a square
boundaryInit:
    addi sp, sp, -4
    sw ra, 0(sp)
    li s2, LED_MATRIX_0_WIDTH
    li s1, LED_MATRIX_0_HEIGHT
    addi s2, s2, -1
    addi s3, x0, -1 # 255 255 255

    VertBoundary:
        beqz s1, EndVertBoundary
        addi s1, s1, -1
        mv a0, s3
        mv a1, x0
        mv a2, s1
        jal setLED

        mv a0, s3
        mv a1, s2
        mv a2, s1
        jal setLED
        j VertBoundary
    EndVertBoundary:
    li s1, LED_MATRIX_0_HEIGHT
    li s2, LED_MATRIX_0_WIDTH
    addi s1, s1, -1
    HorBoundary:
        beqz s2, EndHorBoundary
        addi s2, s2, -1
        
        mv a0, s3
        mv a1, s2
        mv a2, x0
        jal setLED

        mv a0, s3
        mv a1, s2
        mv a2, s1
        jal setLED
                
        j HorBoundary
    EndHorBoundary:
    
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


# Set all LEDs to black. Does not preseve s registers.
# Meant for during program exit
clearScreen:
    addi sp, sp, -4
    sw ra, 0(sp)
    mv s1, x0 # x
    mv s2, x0 # y
    li s4, LED_MATRIX_0_WIDTH
    li s5, LED_MATRIX_0_HEIGHT
    
    CLEARLOOPX:    
        CLEARYLOOPY:
            mv a0, x0
            mv a1, s1
            mv a2, s2
            jal setLED
            
            addi s2, s2, 1
            beq s2, s5, CLEARENDY
            j CLEARYLOOPY
        CLEARENDY:
            mv s2, x0
        addi s1, s1, 1
        beq s1, s4, CLEARENDX
        j CLEARLOOPX
    CLEARENDX:
    
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
    

rand:
    # Implementation from https://en.wikipedia.org/wiki/Linear_congruential_generator
    # Pseudorandom number generator based on LCG
    # Returns 0(a1)*1(a1) + 2(a1) mod a0
    la a1, randseed
    lw t0, 0(a1)
    lw t1, 1(a1)
    lw t2, 2(a1)
    mul t0, t0, t1
    add t0, t0, t2
    remu a0, t0, a0
    sw t0, 1(a1)
    jr ra
    
# Takes in an RGB color in a0, an x-coordinate in a1, and a y-coordinate
# in a2. Then it sets the led at (x, y) to the given color.
setLED:
    li t1, LED_MATRIX_0_WIDTH
    mul t0, a2, t1
    add t0, t0, a1
    li t1, 4
    mul t0, t0, t1
    li t1, LED_MATRIX_0_BASE
    add t0, t1, t0
    sw a0, (0)t0

    jr ra


pollSwitchA:
    mv a0, x0
    li t2, SWITCHES_0_BASE
    lw a0, (0)t2
    jr ra

pollSwitchB:
    mv a0, x0
    li t2, SWITCHES_0_BASE
    lb a0, (1)t2
    jr ra

# Polls the d-pad input until a button is pressed, then returns a number
# representing the button that was pressed in a0.
# The possible return values are:
# 0: UP
# 1: DOWN
# 2: LEFT
# 3: RIGHT
pollDpad:
    mv a0, zero
    li t1, 4
pollLoop:
    bge a0, t1, pollLoopEnd
    li t2, D_PAD_0_BASE
    slli t3, a0, 2
    add t2, t2, t3
    lw t3, (0)t2
    bnez t3, pollRelease
    addi a0, a0, 1
    j pollLoop
pollLoopEnd:
    li a0, 5
    jr ra
pollRelease:
    lw t3, (0)t2
    bnez t3, pollRelease
pollExit:
    # Black out LED where character just was
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw a0, 0(sp)

    la a3, character
    lw a1, 0(a3)
    lw a2, 4(a3)  
    mv a0, x0
    jal setLED
    
    lw a0, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


PLAYERUP:
    # a1 and a2 are x and y coords for the player
    # we survey the square above the player
	    addi a2, a2, -1
    	beqz a2, MOVEMENTDONE # Collision with top wall
	
	    ## No Collision with wall, check collisions with boxes
    	mv a7, s1
    	mv a0, s0
    	UpPlayerBox:
            ## Check every box, see if they are at the coordinate being surveyed
	    	beqz a7, UpPlayerBoxEnd
	
		    lw t1, 0(a0)
    		lw t2, 4(a0)
	        
            ## They aren't at coordinate, move on and keep looking
	    	bne a1, t1, UpPlayerBoxPass
		    bne a2, t2, UpPlayerBoxPass
		        
                ## Found a box at the coordinate,
                ## We do the same search above this box to see if there is another box
                ## or a wall above it.
			    UpBoxBoxCollisionRecursive:
                # Store address of the boxes that are in series and move them up after
                # s7 is the number of boxes that are in series
    			addi s7, s7, 1
	    		addi sp, sp, -4
		    	sw a0, 0(sp)
			    
                ## start the loop again, this time comparing boxes to boxes instead of
                ## player to boxes
			    mv a7, s1
    			mv a0, s0
			
		    	addi a2, t2, -1
			    mv a1, t1
    			UpBoxBoxCollision:
	    			beqz a2, MOVEMENTDONE # The series ends with a wall. Abort movement
		    		beqz a7, UpPlayerBoxEnd
			    	lw t1, 0(a0)
    				lw t2, 4(a0)
	                
	    			bne a1, t1, UpBoxBoxPass
		    		bne a2, t2, UpBoxBoxPass

			    		j UpBoxBoxCollisionRecursive # Found another box in series. Start search again, above this one
				
				    UpBoxBoxPass:
    				addi a7, a7, -2 # Next item in array. 
	    			addi a0, a0, 8
		    		j UpBoxBoxCollision
		
		
    	UpPlayerBoxPass: # This is here for the first loop ( player to box)
	    addi a7, a7, -2
    	addi a0, a0, 8
	    j UpPlayerBox
    	UpPlayerBoxEnd:
	    
        # Movement is allowed to occur
	    la a0, character
    	lw t0, 4(a0)
	    addi t0, t0, -1
    	sw t0, 4(a0)
	
        # Move every box that was in series by popping them off the stack
	    UpBoxChange:
    		beqz s7, MOVEMENTDONE
	    	lw a0, 0(sp)
		    lw t0, 4(a0)
	    	addi t0, t0, -1
    		sw t0, 4(a0)
	    	addi s7, s7, -1
		    addi sp, sp, 4
    	    j UpBoxChange
PLAYERDOWN: # Same as PLAYERUP but with -1 instead of +1
		addi a2, a2, 1
		li t4, LED_MATRIX_0_HEIGHT
		addi t4, t4, -1
		beq a2, t4, MOVEMENTDONE
	
	    ##
    	mv a7, s1
    	mv a0, s0
    	DownPlayerBox:
	    	beqz a7, DownPlayerBoxEnd
	
		    lw t1, 0(a0)
    		lw t2, 4(a0)
	
	    	bne a1, t1, DownPlayerBoxPass
		    bne a2, t2, DownPlayerBoxPass
		
			    DownBoxBoxCollisionRecursive:
    			addi s7, s7, 1
	    		addi sp, sp, -4
		    	sw a0, 0(sp)
			
			
			    mv a7, s1
    			mv a0, s0
			
		    	addi a2, t2, 1
			    mv a1, t1
    			DownBoxBoxCollision:
					li t4, LED_MATRIX_0_HEIGHT
					addi t4, t4, -1
	    			beq a2, t4, MOVEMENTDONE # Need to subtract a7
		    		beqz a7, DownPlayerBoxEnd
			    	lw t1, 0(a0)
    				lw t2, 4(a0)
	
	    			bne a1, t1, DownBoxBoxPass
		    		bne a2, t2, DownBoxBoxPass

			    		j DownBoxBoxCollisionRecursive
				
				    DownBoxBoxPass:
    				addi a7, a7, -2
	    			addi a0, a0, 8
		    		j DownBoxBoxCollision
		
		
    	DownPlayerBoxPass:
	    addi a7, a7, -2
    	addi a0, a0, 8
	    j DownPlayerBox
    	DownPlayerBoxEnd:
	
	    la a0, character
    	lw t0, 4(a0)
	    addi t0, t0, 1
    	sw t0, 4(a0)
	
	    DownBoxChange:
    		beqz s7, MOVEMENTDONE
	    	lw a0, 0(sp)
		    lw t0, 4(a0)
	    	addi t0, t0, 1
    		sw t0, 4(a0)
	    	addi s7, s7, -1
		    addi sp, sp, 4
    	    j DownBoxChange

PLAYERRIGHT:
	    addi a1, a1, 1
		li t4, LED_MATRIX_0_WIDTH
		addi t4, t4, -1
    	beq a1, t4, MOVEMENTDONE
	
	    ##
    	mv a7, s1
    	mv a0, s0
    	RightPlayerBox:
	    	beqz a7, RightPlayerBoxEnd
	
		    lw t1, 0(a0)
    		lw t2, 4(a0)
	
	    	bne a1, t1, RightPlayerBoxPass
		    bne a2, t2, RightPlayerBoxPass
		
			    RightBoxBoxCollisionRecursive:
    			addi s7, s7, 1
	    		addi sp, sp, -4
		    	sw a0, 0(sp)
			
			
			    mv a7, s1
    			mv a0, s0
			
		    	addi a1, t1, 1
			    mv a2, t2
    			RightBoxBoxCollision:
					li t4, LED_MATRIX_0_WIDTH
					addi t4, t4, -1
	    			beq a1, t4, MOVEMENTDONE
		    		beqz a7, RightPlayerBoxEnd
			    	lw t1, 0(a0)
    				lw t2, 4(a0)
	
	    			bne a1, t1, RightBoxBoxPass
		    		bne a2, t2, RightBoxBoxPass

			    		j RightBoxBoxCollisionRecursive
				
				    RightBoxBoxPass:
    				addi a7, a7, -2
	    			addi a0, a0, 8
		    		j RightBoxBoxCollision
		
		
    	RightPlayerBoxPass:
			addi a7, a7, -2
			addi a0, a0, 8
			j RightPlayerBox
    	RightPlayerBoxEnd:
	
	    la a0, character
    	lw t0, 0(a0)
	    addi t0, t0, 1
    	sw t0, 0(a0)
	

	    RightBoxChange:
    		beqz s7, MOVEMENTDONE
	    	lw a0, 0(sp)
		    lw t0, 0(a0)
	    	addi t0, t0, 1
    		sw t0, 0(a0)
	    	addi s7, s7, -1
		    addi sp, sp, 4
    	    j RightBoxChange
	   
PLAYERLEFT:
	    addi a1, a1, -1
    	beqz a1, MOVEMENTDONE # Collision with top wall
	
	    ##
    	mv a7, s1
    	mv a0, s0
    	LeftPlayerBox:
	    	beqz a7, LeftPlayerBoxEnd
	
		    lw t1, 0(a0)
    		lw t2, 4(a0)
	
	    	bne a1, t1, LeftPlayerBoxPass
		    bne a2, t2, LeftPlayerBoxPass
		
			    LeftBoxBoxCollisionRecursive:
    			addi s7, s7, 1
	    		addi sp, sp, -4
		    	sw a0, 0(sp)
			
			
			    mv a7, s1
    			mv a0, s0
			
		    	addi a1, t1, -1
			    mv a2, t2
    			LeftBoxBoxCollision:
	    			beqz a1, MOVEMENTDONE
		    		beqz a7, LeftPlayerBoxEnd
			    	lw t1, 0(a0)
    				lw t2, 4(a0)
	
	    			bne a1, t1, LeftBoxBoxPass
		    		bne a2, t2, LeftBoxBoxPass

			    		j LeftBoxBoxCollisionRecursive
				
				    LeftBoxBoxPass:
    				addi a7, a7, -2
	    			addi a0, a0, 8
		    		j LeftBoxBoxCollision
		
		
    	LeftPlayerBoxPass:
	    addi a7, a7, -2
    	addi a0, a0, 8
	    j LeftPlayerBox
    	LeftPlayerBoxEnd:
	
	    la a0, character
    	lw t0, 0(a0)
	    addi t0, t0, -1
    	sw t0, 0(a0)
	

	    LeftBoxChange:
    		beqz s7, MOVEMENTDONE
	    	lw a0, 0(sp)
		    lw t0, 0(a0)
	    	addi t0, t0, -1
    		sw t0, 0(a0)
	    	addi s7, s7, -1
		    addi sp, sp, 4
    	    j LeftBoxChange
