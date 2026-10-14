import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending follow up override is in its life cycle.
    enum PendingFollowUpOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending follow up override, with what the planners need to act on it.
    final class PendingFollowUpOverride {
        var code: String
        var label: String
        var currency: String
        var retries: Int
        var floorValue: Double
        var pinned: Bool
        var ratio: Double
        var status: PendingFollowUpOverrideStatus

        init(code: String, label: String, currency: String, retries: Int, floorValue: Double, pinned: Bool, ratio: Double, status: PendingFollowUpOverrideStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.retries = retries
            self.floorValue = floorValue
            self.pinned = pinned
            self.ratio = ratio
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

        func canMoveTo(_ next: PendingFollowUpOverrideStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingFollowUpOverrideStatus.cancelled
            case .completed:
                return next == PendingFollowUpOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingFollowUpOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending follow up override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending follow up override") \(code)"
        }

        func adjustedExposure() -> Double {
            return (floorValue * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> PendingFollowUpOverride {
            return PendingFollowUpOverride(
                code: code,
                label: label,
                currency: currency,
                retries: retries,
                floorValue: floorValue,
                pinned: pinned,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending follow up override in status planned.
    static func newPendingFollowUpOverride(_ code: String, label: String) -> PendingFollowUpOverride {
        return PendingFollowUpOverride(
            code: code,
            label: label,
            currency: "",
            retries: 0,
            floorValue: 0.0,
            pinned: false,
            ratio: 0.0,
            status: PendingFollowUpOverrideStatus.planned
        )
    }
}
