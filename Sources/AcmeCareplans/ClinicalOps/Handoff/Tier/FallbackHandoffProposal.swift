import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback handoff proposal is in its life cycle.
    enum FallbackHandoffProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One fallback handoff proposal, with what the planners need to act on it.
    final class FallbackHandoffProposal {
        var code: String
        var name: String
        var specialty: String
        var minimum: Double
        var discount: Double
        var graceDays: Int
        var cost: Double
        var quantity: Int
        var attempts: Int
        var clinicianID: String
        var status: FallbackHandoffProposalStatus

        init(code: String, name: String, specialty: String, minimum: Double, discount: Double, graceDays: Int, cost: Double, quantity: Int, attempts: Int, clinicianID: String, status: FallbackHandoffProposalStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.minimum = minimum
            self.discount = discount
            self.graceDays = graceDays
            self.cost = cost
            self.quantity = quantity
            self.attempts = attempts
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: FallbackHandoffProposalStatus) -> Bool {
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
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackHandoffProposalStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackHandoffProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback handoff proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return ((discount - cost) * 100).rounded() / 100
        }

        func copyValue() -> FallbackHandoffProposal {
            return FallbackHandoffProposal(
                code: code,
                name: name,
                specialty: specialty,
                minimum: minimum,
                discount: discount,
                graceDays: graceDays,
                cost: cost,
                quantity: quantity,
                attempts: attempts,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback handoff proposal in status planned.
    static func newFallbackHandoffProposal(_ code: String, name: String) -> FallbackHandoffProposal {
        return FallbackHandoffProposal(
            code: code,
            name: name,
            specialty: "",
            minimum: 0.0,
            discount: 0.0,
            graceDays: 0,
            cost: 0.0,
            quantity: 0,
            attempts: 0,
            clinicianID: "",
            status: FallbackHandoffProposalStatus.planned
        )
    }
}
