import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime draft is in its life cycle.
    enum OvertimeDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A overtime draft as the overtime team keeps it.
    final class OvertimeDraft {
        var code: String
        var label: String
        var allergy: String
        var timezone: String
        var cost: Double
        var externalRef: String
        var encounterID: String
        var status: OvertimeDraftStatus

        init(code: String, label: String, allergy: String, timezone: String, cost: Double, externalRef: String, encounterID: String, status: OvertimeDraftStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.timezone = timezone
            self.cost = cost
            self.externalRef = externalRef
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OvertimeDraftStatus) -> Bool {
            switch status {
            case .created:
                return next == OvertimeDraftStatus.retired
            case .validated:
                return next == OvertimeDraftStatus.published || next == OvertimeDraftStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: OvertimeDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> OvertimeDraft {
            return OvertimeDraft(
                code: code,
                label: label,
                allergy: allergy,
                timezone: timezone,
                cost: cost,
                externalRef: externalRef,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a overtime draft in status created.
    static func newOvertimeDraft(_ code: String, label: String) -> OvertimeDraft {
        return OvertimeDraft(
            code: code,
            label: label,
            allergy: "",
            timezone: "",
            cost: 0.0,
            externalRef: "",
            encounterID: "",
            status: OvertimeDraftStatus.created
        )
    }
}
