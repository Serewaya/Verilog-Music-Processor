
module audio (
	// Inputs
	CLOCK_50,
	reset,
	AUD_ADCDAT,
	play_enable,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,
	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,
	FPGA_I2C_SCLK
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter AUDIO_DATA_WIDTH = 32;
parameter ROM_SIZE = 156151;  // Number of samples
parameter AUDIO_FRAME_RATE = 5000;  // Frames per second
parameter CLOCK_FREQ = 50000000;  // 50 MHz
parameter CLOCK_CYCLES_PER_FRAME = CLOCK_FREQ / AUDIO_FRAME_RATE;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input 			reset;
input				AUD_ADCDAT;
input				play_enable;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;
inout				FPGA_I2C_SDAT;

// Outputs
output			AUD_XCK;
output			AUD_DACDAT;
output			FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Audio Controller Wires
wire				audio_in_available;
wire	[31:0]		left_channel_audio_in;
wire	[31:0]		right_channel_audio_in;
wire				audio_out_allowed;

// Audio Output Wires
wire	[31:0]		left_channel_audio_out;
wire	[31:0]		right_channel_audio_out;

// ROM Wires
wire	[32:0]		soundout;
wire	[17:0]		rom_address;

// Control Registers
reg	[27:0]		frame_counter;
reg	[17:0]		sample_address;






/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

// State machine removed - simplified to direct play_enable control

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

// Address counter for frame timing
always @(posedge CLOCK_50) begin
	if (reset) begin
		frame_counter <= 0;
	end else if (frame_counter >= CLOCK_CYCLES_PER_FRAME - 1) begin
		frame_counter <= 0;
	end else begin
		frame_counter <= frame_counter + 1;
	end
end

// Sample address increment
always @(posedge CLOCK_50) begin
	if (reset) begin
		sample_address <= 0;
	end else if (play_enable && frame_counter == 0) begin
		if (sample_address >= ROM_SIZE - 1) begin
			sample_address <= 0;  // Loop back to start
		end else begin
			sample_address <= sample_address + 1;
		end
	end
end

// ROM instantiation
assign rom_address = sample_address;
soundrom sample_rom(rom_address, CLOCK_50, soundout);

// Audio output assignment
wire [31:0] audio_sample = soundout >> 2;
assign left_channel_audio_out = play_enable ? audio_sample : 32'h0;
assign right_channel_audio_out = play_enable ? audio_sample : 32'h0;

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

assign audio_in_available = 1'b0;  // Not reading audio input



/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50					(CLOCK_50),
	.reset						(reset),

	.clear_audio_in_memory		(),
	.read_audio_in				(1'b0),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(play_enable & audio_out_allowed),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),

	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)
);

avconf #(.USE_MIC_INPUT(1'b0)) avc (
	.FPGA_I2C_SCLK				(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT				(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(reset)
);

endmodule

