#!/usr/bin/ruby -w
# Reaction game!

require 'ruby2d'
require 'securerandom'

Font =  "#{File.dirname(__FILE__)}/fonts/PlayfairDisplay-Regular.ttf"
FILE = "#{File.dirname(__FILE__)}/score_history.txt"
Glitter_Particles_Count = 200
Stars_Count = 75

STDOUT.sync = true
module Ruby2D
	def total_x() @x + @width end
	def total_y() @y + @height end
end

Square_Width = 60
def main
	@width, @height = 640, 480
	set title: "Reaction Game", width: @width, height: @height, background: "#000000", fps_cap: 60

	message = Text.new '', font: Font
	high_score_text = Text.new '', font: Font
	highest_score = 10
	high_score_text.y = @height - high_score_text.height - 5

	Rectangle.new width: @width, height: @height, color: %w(#000000 #000000 #100022 #200012), z: -5

	square_touched = false
	square = Square.new(size: Square_Width)
	square.x, square.y = @width/2 - square.width/2, @height/2 - square.height/2

	started = false

	on :key_down do |k| close if k.key == 'escape' end

	time = Time.now
	time_counter = Text.new('', font: Font, color: 'blue')
	square_text = Text.new('', font: Font, color: 'black')
	square_pressed = false

	particles, particles_opacity = [], []
	Glitter_Particles_Count.times do
		particles << Square.new(x: rand(square.x..square.total_x), y: rand(square.y..square.total_y), opacity: 1, size: rand(1.0..2.0))
		particles_opacity << rand(0.003..0.02)
	end
	particles.freeze
	particles_size = particles.size

	stars, stars_y = [], []
	Stars_Count.times do
			stars << Square.new(x: rand(0..@width), y: rand(0..@height), size: rand(1.0..2.0))
			stars_y << rand(0.1..5)
	end
	stars.freeze
	stars_size = stars.size

	on :mouse_down do |e|
		if square.contains?(e.x, e.y)
				square.size = Square_Width
				square.x, square.y = rand(0..@width - square.width), rand(0..@height - square.height)
				time_counter.color = "##{SecureRandom.hex(3)}"
				square_text.color = time_counter.r, time_counter.g, time_counter.b, 1
				square_touched = false

			if started
				square_pressed = true
				time_taken = Time.now - time
				message.text = "You did it in #{(time_taken * 1000).to_i} milliseconds!"
				square_text.text = "#{(time_taken * 1000).to_i} ms!"
				particles.sample(particles_size/2).each { |val| val.x, val.y = rand(square.x..square.total_x), rand(square.y..square.total_y) }
				File.open(FILE, 'a') { |file| file.puts "#{Time.new.strftime('%d-%m-%y, %H:%M:%S')} => #{(time_taken * 1000).to_i} ms!"}
				STDOUT.puts "#{(time_taken * 1000).to_i} ms!"

				highest_score = time_taken if time_taken < highest_score
				high_score_text.text = "Best Reaction Time: #{highest_score.round(5)} seconds"
			end
			time = Time.now
			started ||= true
		end
	end

	on :mouse_move do |e|
		square_touched = square.contains?(e.x, e.y) ? true : false
		started = (e.x < @width - 1 && e.x > 1 && e.y < @height - 1 && e.y > 1 && started) ? true : false
	end

	update do
		time_counter.x, time_counter.y = square.x + square.width/2 - time_counter.width/2, square.y + square.height/4 - time_counter.height/2
		message.x, high_score_text.x = @width/2 - message.width/2, @width/2 - high_score_text.width/2
		square_text.x, square_text.y = square.x + square.width/2 - square_text.width/2, square.y + square.height/1.5 - square_text.height/2

		if square_pressed then square_text.opacity = 1
		else square_text.opacity -= 0.01 if square_text.opacity > 0 end
		square_pressed = false if square_text.opacity >= 1

		if square_touched then square.opacity -= 0.03 if square.opacity > 0.8
		else square.opacity += 0.03 if square.opacity < 1 end

 		if square.size <= Square_Width * 2
			square.size += 4
			square.x -= 2
			square.y -=2
		end

		if started
			time_counter.text = "#{(Time.now - time).round(3)} s"

			particles_size.times do |temp|
				val = particles[temp]

				val.x -= Math.sin(temp)
				val.y -= rand(0.5..4.0)

				val_opacity, val.color = val.opacity, "##{SecureRandom.hex(3)}"
				val.opacity = val_opacity

				val.z = [-10,-1].sample
				val.opacity -= particles_opacity[temp]

				val.x, val.y, val.opacity = rand(square.x..square.total_x), rand(square.y..square.total_y), rand(1.0..2.0) if val.opacity <= 0 || val.y < -val.height
			end
		else
			message.text = "Click the Square to Start!"
			time_counter.text = 'Start!'
			particles.each { |val| val.opacity = 0 }
		end

		stars_size.times do |temp|
			val = stars[temp]
			val.z = [-10, 0].sample if stars_y[temp] < 1.5
			val.y += stars_y[temp]
			if val.y >= @height + val.height
				val.x, val.y = rand(0..@width), 0
				stars_y[temp] = rand(0.1..5)
			end
		end
	end

	at_exit do
		File.open(FILE, 'a') { |file| file.puts(high_score_text.text + "\n\n" + "-" * 25) }
		STDOUT.puts high_score_text.text + "\n\n" + "-" * 25
	end
	show
end

main
