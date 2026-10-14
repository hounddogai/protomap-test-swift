import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff schedule is in its life cycle.
    enum HandoffScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A handoff schedule as the handoff team keeps it.
    final class HandoffSchedule {
        var code: String
        var label: String
        var pinned: Bool
        var diagnosisCode: String
        var unit: String
        var description: String
        var quantity: Int
        var score: Double
        var encounterID: String
        var status: HandoffScheduleStatus

        init(code: String, label: String, pinned: Bool, diagnosisCode: String, unit: String, description: String, quantity: Int, score: Double, encounterID: String, status: HandoffScheduleStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.diagnosisCode = diagnosisCode
            self.unit = unit
            self.description = description
            self.quantity = quantity
            self.score = score
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

        func canMoveTo(_ next: HandoffScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == HandoffScheduleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return ((score - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffSchedule {
            return HandoffSchedule(
                code: code,
                label: label,
                pinned: pinned,
                diagnosisCode: diagnosisCode,
                unit: unit,
                description: description,
                quantity: quantity,
                score: score,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a handoff schedule in status proposed.
    static func newHandoffSchedule(_ code: String, label: String) -> HandoffSchedule {
        return HandoffSchedule(
            code: code,
            label: label,
            pinned: false,
            diagnosisCode: "",
            unit: "",
            description: "",
            quantity: 0,
            score: 0.0,
            encounterID: "",
            status: HandoffScheduleStatus.proposed
        )
    }
}
