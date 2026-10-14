import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered follow up profile is in its life cycle.
    enum TieredFollowUpProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered follow up profile and its current status.
    final class TieredFollowUpProfile {
        var code: String
        var label: String
        var procedureCode: String
        var specialty: String
        var allergy: String
        var notes: String
        var quantity: Int
        var status: TieredFollowUpProfileStatus

        init(code: String, label: String, procedureCode: String, specialty: String, allergy: String, notes: String, quantity: Int, status: TieredFollowUpProfileStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.allergy = allergy
            self.notes = notes
            self.quantity = quantity
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

        func canMoveTo(_ next: TieredFollowUpProfileStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredFollowUpProfileStatus.pending || next == TieredFollowUpProfileStatus.active
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TieredFollowUpProfileStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TieredFollowUpProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered follow up profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> TieredFollowUpProfile {
            return TieredFollowUpProfile(
                code: code,
                label: label,
                procedureCode: procedureCode,
                specialty: specialty,
                allergy: allergy,
                notes: notes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered follow up profile in status draft.
    static func newTieredFollowUpProfile(_ code: String, label: String) -> TieredFollowUpProfile {
        return TieredFollowUpProfile(
            code: code,
            label: label,
            procedureCode: "",
            specialty: "",
            allergy: "",
            notes: "",
            quantity: 0,
            status: TieredFollowUpProfileStatus.draft
        )
    }
}
