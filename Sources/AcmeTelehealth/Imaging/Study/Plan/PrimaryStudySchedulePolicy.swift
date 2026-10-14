import AcmePlatform
import Foundation

extension Imaging {
    static func mergePrimaryStudyScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 39212.0, in order.
    static func primaryStudyScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39212.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
