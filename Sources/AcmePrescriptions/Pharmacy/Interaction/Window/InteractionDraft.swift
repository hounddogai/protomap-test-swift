import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction draft is in its life cycle.
    enum InteractionDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a interaction draft and its current status.
    final class InteractionDraft {
        var code: String
        var label: String
        var batchSize: Int
        var allergy: String
        var phone: String
        var cost: Double
        var bed: String
        var graceDays: Int
        var approved: Bool
        var copay: Double
        var status: InteractionDraftStatus

        init(code: String, label: String, batchSize: Int, allergy: String, phone: String, cost: Double, bed: String, graceDays: Int, approved: Bool, copay: Double, status: InteractionDraftStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.allergy = allergy
            self.phone = phone
            self.cost = cost
            self.bed = bed
            self.graceDays = graceDays
            self.approved = approved
            self.copay = copay
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

        func canMoveTo(_ next: InteractionDraftStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == InteractionDraftStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("interaction draft") \(code)"
        }

        func weightedExposure() -> Double {
            return ((cost - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionDraft {
            return InteractionDraft(
                code: code,
                label: label,
                batchSize: batchSize,
                allergy: allergy,
                phone: phone,
                cost: cost,
                bed: bed,
                graceDays: graceDays,
                approved: approved,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a interaction draft in status draft.
    static func newInteractionDraft(_ code: String, label: String) -> InteractionDraft {
        return InteractionDraft(
            code: code,
            label: label,
            batchSize: 0,
            allergy: "",
            phone: "",
            cost: 0.0,
            bed: "",
            graceDays: 0,
            approved: false,
            copay: 0.0,
            status: InteractionDraftStatus.draft
        )
    }
}
