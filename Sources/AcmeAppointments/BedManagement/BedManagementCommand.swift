import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            _ = Kit.Clocks.system()
            _ = Kit.Text.normalize(newBedBoardRecord("seed", title: "Seed").label())
        }
    }
}
