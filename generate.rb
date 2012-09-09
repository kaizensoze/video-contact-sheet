#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'pp'
require 'fileutils'


def escape_for_regex(str)
  # path.gsub(/([\[\]\{\}\*\?\\])/, '\\\\\1')
  return str.gsub(/([\[\]\{\}\(\)\*\+\?\\\^\$\|\ \'\"])/, "\\\\\1")
end

def run
  input_video_filename = ARGV[0]
  if input_video_filename.nil?
    abort("Aborting. (Please provide an input video filepath).")
  end

  input_video_filename = Regexp.escape(input_video_filename)

  # Get info on video using ffmpeg.
  output = `ffprobe -v quiet -print_format json -pretty -show_format -show_streams #{input_video_filename}`
  
  ffmpeg_info = JSON.parse(output)
  # pp ffmpeg_info

  format = ffmpeg_info['format']
  filename = format['filename'].split('/').pop()
  duration = format['duration'].split('.')[0]

  filesize_pieces = format['size'].split(' ')
  filesize = "#{filesize_pieces[0].to_f.round} #{filesize_pieces[1]}"

  tracks = ffmpeg_info['streams']
  video_track = nil
  tracks.each do |track|
    if track['codec_type'] == 'video'
      video_track = track
      break
    end
  end

  if video_track.nil?
    abort("Aborting. (No video track detected).")
  end

  resolution = "#{video_track['width']}x#{video_track['height']}"

  video_info = {
    :filename => filename,
    :duration => duration,
    :filesize => filesize,
    :resolution => resolution
  }
  
  montage_config = {
    :dimensions => '326x246',
    :cols => 3,
    :rows => 8
  }
  montage_config[:num_thumbnails] = montage_config[:cols] * montage_config[:rows]

  video_duration_in_seconds = 0;
  video_duration = video_info[:duration];
  video_duration_pieces = video_duration.split(':');
  video_duration_pieces.reverse!
  video_duration_pieces.each_with_index do |video_duration_piece, idx|
    video_duration_in_seconds += video_duration_piece.to_i * (60 ** idx)
  end

  video_info[:duration_in_seconds] = video_duration_in_seconds

  # Create temp folder to store thumbnails.
  thumbnail_folder_name = 'video-thumbnails-temp'
  begin
    Dir.mkdir(thumbnail_folder_name)
  rescue Exception => ex
  end

  (0..montage_config[:num_thumbnails]-1).to_a.each do |i|
    ss_val = i * (video_info[:duration_in_seconds] / montage_config[:num_thumbnails])
    `ffmpeg -v quiet -ss #{ss_val} -i #{input_video_filename} -s #{montage_config[:dimensions]} #{thumbnail_folder_name}/#{i+1}.png`
  end

  cols = montage_config[:cols]
  rows = montage_config[:rows]
  dimensions = montage_config[:dimensions]
  `cd #{thumbnail_folder_name} && montage -quiet $(ls | sort -n) -label 'blah' -tile #{cols}x#{rows} -geometry #{dimensions}+1+1 ../montage.png`

  # convert montage.png -gravity North -background white -fill black -font Helvetica -splice 0x200 -annotate +0+2 'Testing' annotated_montage.png

  # Remove temp thumbnail folder.
  begin
    FileUtils.rm_rf(thumbnail_folder_name)
  rescue Exception => ex
  end
end

if __FILE__ == $0
  run()
end
