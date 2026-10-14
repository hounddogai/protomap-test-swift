import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled witness milestone is in its life cycle.
    enum ScheduledWitnessMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One scheduled witness milestone, with what the planners need to act on it.
    final class ScheduledWitnessMilestone {
        var code: String
        var title: String
        var unit: String
        var specialty: String
        var version: Int
        var label: String
        var status: ScheduledWitnessMilestoneStatus

        init(code: String, title: String, unit: String, specialty: String, version: Int, label: String, status: ScheduledWitnessMilestoneStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.specialty = specialty
            self.version = version
            self.label = label
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledWitnessMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ScheduledWitnessMilestoneStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledWitnessMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled witness milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> ScheduledWitnessMilestone {
            return ScheduledWitnessMilestone(
                code: code,
                title: title,
                unit: unit,
                specialty: specialty,
                version: version,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled witness milestone in status requested.
    static func newScheduledWitnessMilestone(_ code: String, title: String) -> ScheduledWitnessMilestone {
        return ScheduledWitnessMilestone(
            code: code,
            title: title,
            unit: "",
            specialty: "",
            version: 0,
            label: "",
            status: ScheduledWitnessMilestoneStatus.requested
        )
    }
}
