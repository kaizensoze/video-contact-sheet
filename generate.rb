#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'pp'


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
  begin
    Dir.mkdir('video-thumbnails-temp')
  rescue
  end

  

  # Remove temp thumbnail folder.
  begin
    Dir.rmdir('video-thumbnails-temp')
  rescue
  end
end

if __FILE__ == $0
  run()
end
