import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial override is in its life cycle.
    enum DenialOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a denial override and its current status.
    final class DenialOverride {
        var code: String
        var title: String
        var endsAt: Int
        var ceiling: Double
        var segment: String
        var status: DenialOverrideStatus

        init(code: String, title: String, endsAt: Int, ceiling: Double, segment: String, status: DenialOverrideStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.ceiling = ceiling
            self.segment = segment
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

        func canMoveTo(_ next: DenialOverrideStatus) -> Bool {
            switch status {
            case .planned:
                return next == DenialOverrideStatus.inProgress
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DenialOverrideStatus.completed || next == DenialOverrideStatus.cancelled
            case .completed:
                return next == DenialOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return ((ceiling - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> DenialOverride {
            return DenialOverride(
                code: code,
                title: title,
                endsAt: endsAt,
                ceiling: ceiling,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a denial override in status planned.
    static func newDenialOverride(_ code: String, title: String) -> DenialOverride {
        return DenialOverride(
            code: code,
            title: title,
            endsAt: 0,
            ceiling: 0.0,
            segment: "",
            status: DenialOverrideStatus.planned
        )
    }
}
