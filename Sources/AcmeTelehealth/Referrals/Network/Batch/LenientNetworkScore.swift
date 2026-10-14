import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient network score is in its life cycle.
    enum LenientNetworkScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient network score. Its code is unique within a tenant.
    final class LenientNetworkScore {
        var code: String
        var label: String
        var pinned: Bool
        var floorValue: Double
        var copay: Double
        var summary: String
        var endsAt: Int
        var attempts: Int
        var status: LenientNetworkScoreStatus

        init(code: String, label: String, pinned: Bool, floorValue: Double, copay: Double, summary: String, endsAt: Int, attempts: Int, status: LenientNetworkScoreStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.floorValue = floorValue
            self.copay = copay
            self.summary = summary
            self.endsAt = endsAt
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientNetworkScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientNetworkScoreStatus.cancelled
            case .scheduled:
                return next == LenientNetworkScoreStatus.cancelled
            case .inProgress:
                return next == LenientNetworkScoreStatus.completed
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientNetworkScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient network score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return (copay * floorValue * 100).rounded() / 100
        }

        func copyValue() -> LenientNetworkScore {
            return LenientNetworkScore(
                code: code,
                label: label,
                pinned: pinned,
                floorValue: floorValue,
                copay: copay,
                summary: summary,
                endsAt: endsAt,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient network score in status planned.
    static func newLenientNetworkScore(_ code: String, label: String) -> LenientNetworkScore {
        return LenientNetworkScore(
            code: code,
            label: label,
            pinned: false,
            floorValue: 0.0,
            copay: 0.0,
            summary: "",
            endsAt: 0,
            attempts: 0,
            status: LenientNetworkScoreStatus.planned
        )
    }
}
