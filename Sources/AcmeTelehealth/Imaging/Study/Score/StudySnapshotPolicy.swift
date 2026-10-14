import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 8711.0, in order.
    static func studySnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8711.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func studySnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
