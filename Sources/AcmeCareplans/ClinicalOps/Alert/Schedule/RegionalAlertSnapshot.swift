import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional alert snapshot is in its life cycle.
    enum RegionalAlertSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional alert snapshot as the alert team keeps it.
    final class RegionalAlertSnapshot {
        var code: String
        var label: String
        var contactEmail: String
        var cost: Double
        var country: String
        var status: RegionalAlertSnapshotStatus

        init(code: String, label: String, contactEmail: String, cost: Double, country: String, status: RegionalAlertSnapshotStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.cost = cost
            self.country = country
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

        func canMoveTo(_ next: RegionalAlertSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalAlertSnapshotStatus.completed
            case .inProgress:
                return next == RegionalAlertSnapshotStatus.cancelled
            case .completed:
                return next == RegionalAlertSnapshotStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAlertSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional alert snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> RegionalAlertSnapshot {
            return RegionalAlertSnapshot(
                code: code,
                label: label,
                contactEmail: contactEmail,
                cost: cost,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional alert snapshot in status planned.
    static func newRegionalAlertSnapshot(_ code: String, label: String) -> RegionalAlertSnapshot {
        return RegionalAlertSnapshot(
            code: code,
            label: label,
            contactEmail: "",
            cost: 0.0,
            country: "",
            status: RegionalAlertSnapshotStatus.planned
        )
    }
}
