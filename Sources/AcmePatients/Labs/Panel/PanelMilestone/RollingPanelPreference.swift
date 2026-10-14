import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling panel preference is in its life cycle.
    enum RollingPanelPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling panel preference as the panel team keeps it.
    final class RollingPanelPreference {
        var code: String
        var label: String
        var maximum: Double
        var contactEmail: String
        var floorValue: Double
        var bed: String
        var status: RollingPanelPreferenceStatus

        init(code: String, label: String, maximum: Double, contactEmail: String, floorValue: Double, bed: String, status: RollingPanelPreferenceStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.bed = bed
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

        func canMoveTo(_ next: RollingPanelPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingPanelPreferenceStatus.completed || next == RollingPanelPreferenceStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingPanelPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling panel preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling panel preference") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((maximum + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RollingPanelPreference {
            return RollingPanelPreference(
                code: code,
                label: label,
                maximum: maximum,
                contactEmail: contactEmail,
                floorValue: floorValue,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling panel preference in status planned.
    static func newRollingPanelPreference(_ code: String, label: String) -> RollingPanelPreference {
        return RollingPanelPreference(
            code: code,
            label: label,
            maximum: 0.0,
            contactEmail: "",
            floorValue: 0.0,
            bed: "",
            status: RollingPanelPreferenceStatus.planned
        )
    }
}
