import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness milestone is in its life cycle.
    enum WitnessMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A witness milestone. Its code is unique within a tenant.
    final class WitnessMilestone {
        var code: String
        var title: String
        var specialty: String
        var unit: String
        var encounterID: String
        var score: Double
        var status: WitnessMilestoneStatus

        init(code: String, title: String, specialty: String, unit: String, encounterID: String, score: Double, status: WitnessMilestoneStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.unit = unit
            self.encounterID = encounterID
            self.score = score
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

        func canMoveTo(_ next: WitnessMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WitnessMilestoneStatus.rejected
            case .approved:
                return next == WitnessMilestoneStatus.withdrawn
            case .rejected:
                return next == WitnessMilestoneStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> WitnessMilestone {
            return WitnessMilestone(
                code: code,
                title: title,
                specialty: specialty,
                unit: unit,
                encounterID: encounterID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a witness milestone in status proposed.
    static func newWitnessMilestone(_ code: String, title: String) -> WitnessMilestone {
        return WitnessMilestone(
            code: code,
            title: title,
            specialty: "",
            unit: "",
            encounterID: "",
            score: 0.0,
            status: WitnessMilestoneStatus.proposed
        )
    }
}
