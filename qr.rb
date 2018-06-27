#! ruby -Ku
# encoding: utf-8

require "RMagick"
require "fileutils"

PATH_ZBAR = 'C:\Program Files (x86)\ZBar\bin\zbarimg.exe'
DIR_IMG = './out'

def load_img
  @img_qr = Magick::ImageList.new("./qr.png").first
  @img_qr_mask = Magick::ImageList.new("./qr_mask.png").first
  @img_ks = Magick::ImageList.new("./ks.png").first
  @img_ks_mask = Magick::ImageList.new("./ks_mask.png").first
end

def ks_or_qr(x, y)
  img_ks_mask_resize = Magick::Image.new(
  @img_qr_mask.columns, @img_qr_mask.rows) {
    self.background_color = "white"
  }
  img_ks_mask_resize.composite!(@img_ks_mask, x, y, Magick::OverCompositeOp)
  imgl = Magick::ImageList.new
  imgl << img_ks_mask_resize
  imgl << @img_qr_mask
  img_qr_or_ks = imgl.fx("u|v")
  hist = img_qr_or_ks.color_histogram
  black_px = 0
  hist.each do |key, value|
    black_px = value if key.to_color == "black"
  end
  img_ks_mask_resize.destroy!
  black_px
end

def ks_over_qr(x, y, black_px)
  path_img = "#{DIR_IMG}/y%04d_x%04d_b%06d.png" % [y, x, black_px]
  img_qr_cp = @img_qr.copy
  img_qr_cp.composite!(@img_ks, x, y, Magick::OverCompositeOp)
  img_qr_cp.write(path_img)
  img_qr_cp.destroy!
  path_img
end

def zbar(path_img)
  stdout = `"#{PATH_ZBAR}" -q #{path_img}`
  result = stdout == "QR-Code:志村 けん（しむら けん、1950年2月20日 - ）は、" \
                     "日本のコメディアン、お笑いタレント、司会者。\n"
  path_img_result = "#{File.dirname(path_img)}/" \
                    "#{File.basename(path_img, ".png")}_" \
                    "#{result ? "o" : "x"}.png"
  FileUtils.mv(path_img, path_img_result)
end

def execute
  load_img
  0.step(@img_qr.rows, 100) do |y|
    0.step(@img_qr.columns, 100) do |x|
      black_px = ks_or_qr(x, y)
      path_img = ks_over_qr(x, y, black_px)
      zbar(path_img)
    end
  end
end

execute
