import AcmePlatform
import Foundation

extension BedManagement {
    static func pendingBedBoardReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingBedBoardReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-bed-board-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
