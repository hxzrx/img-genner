(in-package "img-genner")
(defvar *color-names* (make-hash-table))
(defun def-color(name r g b)
  (setf (gethash name *color-names*)
        (vector r g b)))

(let ((little-endian (member :little-endian *features*)))
      (defun def-hex-color(name c)
        (setf (gethash name *color-names*)
              (if little-endian
                  (vector (ldb (byte 8 16) c)
                          (ldb (byte 8 8) c)
                          (ldb (byte 8 0) c))
                  (vector (ldb (byte 8 0) c)
                          (ldb (byte 8 8) c)
                          (ldb (byte 8 16) c)))
              )))
(export '(def-hex-color def-color))
(def-hex-color "AliceBlue" #xF0F8FF)
(def-hex-color "AntiqueWhite" #xFAEBD7)
(def-hex-color "Aqua" #x00FFFF)
(def-hex-color "Aquamarine" #x7FFFD4)
(def-hex-color "Azure" #xF0FFFF)
(def-hex-color "Beige" #xF5F5DC)
(def-hex-color "Bisque" #xFFE4C4)
(def-hex-color "Black" #x000000)
(def-hex-color "BlanchedAlmond" #xFFEBCD)
(def-hex-color "Blue" #x0000FF)
(def-hex-color "BlueViolet" #x8A2BE2)
(def-hex-color "Brown" #xA52A2A)
(def-hex-color "BurlyWood" #xDEB887)
(def-hex-color "CadetBlue" #x5F9EA0)
(def-hex-color "Chartreuse" #x7FFF00)
(def-hex-color "Chocolate" #xD2691E)
(def-hex-color "Coral" #xFF7F50)
(def-hex-color "CornflowerBlue" #x6495ED)
(def-hex-color "Cornsilk" #xFFF8DC)
(def-hex-color "Crimson" #xDC143C)
(def-hex-color "Cyan" #x00FFFF)
(def-hex-color "DarkBlue" #x00008B)
(def-hex-color "DarkCyan" #x008B8B)
(def-hex-color "DarkGoldenRod" #xB8860B)
(def-hex-color "DarkGray" #xA9A9A9)
(def-hex-color "DarkGrey" #xA9A9A9)
(def-hex-color "DarkGreen" #x006400)
(def-hex-color "DarkKhaki" #xBDB76B)
(def-hex-color "DarkMagenta" #x8B008B)
(def-hex-color "DarkOliveGreen" #x556B2F)
(def-hex-color "DarkOrange" #xFF8C00)
(def-hex-color "DarkOrchid" #x9932CC)
(def-hex-color "DarkRed" #x8B0000)
(def-hex-color "DarkSalmon" #xE9967A)
(def-hex-color "DarkSeaGreen" #x8FBC8F)
(def-hex-color "DarkSlateBlue" #x483D8B)
(def-hex-color "DarkSlateGray" #x2F4F4F)
(def-hex-color "DarkSlateGrey" #x2F4F4F)
(def-hex-color "DarkTurquoise" #x00CED1)
(def-hex-color "DarkViolet" #x9400D3)
(def-hex-color "DeepPink" #xFF1493)
(def-hex-color "DeepSkyBlue" #x00BFFF)
(def-hex-color "DimGray" #x696969)
(def-hex-color "DimGrey" #x696969)
(def-hex-color "DodgerBlue" #x1E90FF)
(def-hex-color "FireBrick" #xB22222)
(def-hex-color "FloralWhite" #xFFFAF0)
(def-hex-color "ForestGreen" #x228B22)
(def-hex-color "Fuchsia" #xFF00FF)
(def-hex-color "Gainsboro" #xDCDCDC)
(def-hex-color "GhostWhite" #xF8F8FF)
(def-hex-color "Gold" #xFFD700)
(def-hex-color "GoldenRod" #xDAA520)
(def-hex-color "Gray" #x808080)
(def-hex-color "Grey" #x808080)
(def-hex-color "Green" #x008000)
(def-hex-color "GreenYellow" #xADFF2F)
(def-hex-color "HoneyDew" #xF0FFF0)
(def-hex-color "HotPink" #xFF69B4)
(def-hex-color "IndianRed " #xCD5C5C)
(def-hex-color "Indigo " #x4B0082)
(def-hex-color "Ivory" #xFFFFF0)
(def-hex-color "Khaki" #xF0E68C)
(def-hex-color "Lavender" #xE6E6FA)
(def-hex-color "LavenderBlush" #xFFF0F5)
(def-hex-color "LawnGreen" #x7CFC00)
(def-hex-color "LemonChiffon" #xFFFACD)
(def-hex-color "LightBlue" #xADD8E6)
(def-hex-color "LightCoral" #xF08080)
(def-hex-color "LightCyan" #xE0FFFF)
(def-hex-color "LightGoldenRodYellow" #xFAFAD2)
(def-hex-color "LightGray" #xD3D3D3)
(def-hex-color "LightGrey" #xD3D3D3)
(def-hex-color "LightGreen" #x90EE90)
(def-hex-color "LightPink" #xFFB6C1)
(def-hex-color "LightSalmon" #xFFA07A)
(def-hex-color "LightSeaGreen" #x20B2AA)
(def-hex-color "LightSkyBlue" #x87CEFA)
(def-hex-color "LightSlateGray" #x778899)
(def-hex-color "LightSlateGrey" #x778899)
(def-hex-color "LightSteelBlue" #xB0C4DE)
(def-hex-color "LightYellow" #xFFFFE0)
(def-hex-color "Lime" #x00FF00)
(def-hex-color "LimeGreen" #x32CD32)
(def-hex-color "Linen" #xFAF0E6)
(def-hex-color "Magenta" #xFF00FF)
(def-hex-color "Maroon" #x800000)
(def-hex-color "MediumAquaMarine" #x66CDAA)
(def-hex-color "MediumBlue" #x0000CD)
(def-hex-color "MediumOrchid" #xBA55D3)
(def-hex-color "MediumPurple" #x9370DB)
(def-hex-color "MediumSeaGreen" #x3CB371)
(def-hex-color "MediumSlateBlue" #x7B68EE)
(def-hex-color "MediumSpringGreen" #x00FA9A)
(def-hex-color "MediumTurquoise" #x48D1CC)
(def-hex-color "MediumVioletRed" #xC71585)
(def-hex-color "MidnightBlue" #x191970)
(def-hex-color "MintCream" #xF5FFFA)
(def-hex-color "MistyRose" #xFFE4E1)
(def-hex-color "Moccasin" #xFFE4B5)
(def-hex-color "NavajoWhite" #xFFDEAD)
(def-hex-color "Navy" #x000080)
(def-hex-color "OldLace" #xFDF5E6)
(def-hex-color "Olive" #x808000)
(def-hex-color "OliveDrab" #x6B8E23)
(def-hex-color "Orange" #xFFA500)
(def-hex-color "OrangeRed" #xFF4500)
(def-hex-color "Orchid" #xDA70D6)
(def-hex-color "PaleGoldenRod" #xEEE8AA)
(def-hex-color "PaleGreen" #x98FB98)
(def-hex-color "PaleTurquoise" #xAFEEEE)
(def-hex-color "PaleVioletRed" #xDB7093)
(def-hex-color "PapayaWhip" #xFFEFD5)
(def-hex-color "PeachPuff" #xFFDAB9)
(def-hex-color "Peru" #xCD853F)
(def-hex-color "Pink" #xFFC0CB)
(def-hex-color "Plum" #xDDA0DD)
(def-hex-color "PowderBlue" #xB0E0E6)
(def-hex-color "Purple" #x800080)
(def-hex-color "RebeccaPurple" #x663399)
(def-hex-color "Red" #xFF0000)
(def-hex-color "RosyBrown" #xBC8F8F)
(def-hex-color "RoyalBlue" #x4169E1)
(def-hex-color "SaddleBrown" #x8B4513)
(def-hex-color "Salmon" #xFA8072)
(def-hex-color "SandyBrown" #xF4A460)
(def-hex-color "SeaGreen" #x2E8B57)
(def-hex-color "SeaShell" #xFFF5EE)
(def-hex-color "Sienna" #xA0522D)
(def-hex-color "Silver" #xC0C0C0)
(def-hex-color "SkyBlue" #x87CEEB)
(def-hex-color "SlateBlue" #x6A5ACD)
(def-hex-color "SlateGray" #x708090)
(def-hex-color "SlateGrey" #x708090)
(def-hex-color "Snow" #xFFFAFA)
(def-hex-color "SpringGreen" #x00FF7F)
(def-hex-color "SteelBlue" #x4682B4)
(def-hex-color "Tan" #xD2B48C)
(def-hex-color "Teal" #x008080)
(def-hex-color "Thistle" #xD8BFD8)
(def-hex-color "Tomato" #xFF6347)
(def-hex-color "Turquoise" #x40E0D0)
(def-hex-color "Violet" #xEE82EE)
(def-hex-color "Wheat" #xF5DEB3)
(def-hex-color "White" #xFFFFFF)
(def-hex-color "WhiteSmoke" #xF5F5F5)
(def-hex-color "Yellow" #xFFFF00)
(def-hex-color "YellowGreen" #x9ACD32)

(let ((color (gethash "Yellow" *color-names*)))
  (assert (and
           (= (aref color 0) 255 )
           (= (aref color 1) 255)
           (= (aref color 2) 0))))
