import AcmePlatform
import Foundation

extension Labs {
    /// Where a global result preference is in its life cycle.
    enum GlobalResultPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global result preference, with what the planners need to act on it.
    final class GlobalResultPreference {
        var code: String
        var label: String
        var cost: Double
        var archived: Bool
        var unit: String
        var country: String
        var encounterID: String
        var status: GlobalResultPreferenceStatus

        init(code: String, label: String, cost: Double, archived: Bool, unit: String, country: String, encounterID: String, status: GlobalResultPreferenceStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.archived = archived
            self.unit = unit
            self.country = country
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalResultPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalResultPreferenceStatus.approved
            case .approved:
                return next == GlobalResultPreferenceStatus.rejected || next == GlobalResultPreferenceStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GlobalResultPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global result preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> GlobalResultPreference {
            return GlobalResultPreference(
                code: code,
                label: label,
                cost: cost,
                archived: archived,
                unit: unit,
                country: country,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global result preference in status proposed.
    static func newGlobalResultPreference(_ code: String, label: String) -> GlobalResultPreference {
        return GlobalResultPreference(
            code: code,
            label: label,
            cost: 0.0,
            archived: false,
            unit: "",
            country: "",
            encounterID: "",
            status: GlobalResultPreferenceStatus.proposed
        )
    }
}
