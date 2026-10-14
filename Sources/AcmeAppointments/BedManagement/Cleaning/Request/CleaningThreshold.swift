import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning threshold is in its life cycle.
    enum CleaningThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One cleaning threshold, with what the planners need to act on it.
    final class CleaningThreshold {
        var code: String
        var label: String
        var endsAt: Int
        var timezone: String
        var quantity: Int
        var status: CleaningThresholdStatus

        init(code: String, label: String, endsAt: Int, timezone: String, quantity: Int, status: CleaningThresholdStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.timezone = timezone
            self.quantity = quantity
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

        func canMoveTo(_ next: CleaningThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CleaningThresholdStatus.inProgress || next == CleaningThresholdStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CleaningThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(quantity) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningThreshold {
            return CleaningThreshold(
                code: code,
                label: label,
                endsAt: endsAt,
                timezone: timezone,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a cleaning threshold in status planned.
    static func newCleaningThreshold(_ code: String, label: String) -> CleaningThreshold {
        return CleaningThreshold(
            code: code,
            label: label,
            endsAt: 0,
            timezone: "",
            quantity: 0,
            status: CleaningThresholdStatus.planned
        )
    }
}
