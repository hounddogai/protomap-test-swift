import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled charge digest is in its life cycle.
    enum ScheduledChargeDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a scheduled charge digest and its current status.
    final class ScheduledChargeDigest {
        var code: String
        var name: String
        var category: String
        var label: String
        var windowDays: Int
        var status: ScheduledChargeDigestStatus

        init(code: String, name: String, category: String, label: String, windowDays: Int, status: ScheduledChargeDigestStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.label = label
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledChargeDigestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ScheduledChargeDigestStatus.active
            case .active:
                return next == ScheduledChargeDigestStatus.closed
            case .suspended:
                return next == ScheduledChargeDigestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledChargeDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled charge digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> ScheduledChargeDigest {
            return ScheduledChargeDigest(
                code: code,
                name: name,
                category: category,
                label: label,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a scheduled charge digest in status draft.
    static func newScheduledChargeDigest(_ code: String, name: String) -> ScheduledChargeDigest {
        return ScheduledChargeDigest(
            code: code,
            name: name,
            category: "",
            label: "",
            windowDays: 0,
            status: ScheduledChargeDigestStatus.draft
        )
    }
}
