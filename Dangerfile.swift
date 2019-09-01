import Danger 
import Foundation
let danger = Danger()

SwiftLint.lint(configFile: ".swiftlint.yml", lintAllFiles: true)
