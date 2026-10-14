import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary rounding profile is in its life cycle.
    enum PrimaryRoundingProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary rounding profile and its current status.
    final class PrimaryRoundingProfile {
        var code: String
        var title: String
        var retries: Int
        var sequence: Int
        var discount: Double
        var cost: Double
        var budget: Double
        var patientRef: String
        var copay: Double
        var acuity: Int
        var capacity: Int
        var status: PrimaryRoundingProfileStatus

        init(code: String, title: String, retries: Int, sequence: Int, discount: Double, cost: Double, budget: Double, patientRef: String, copay: Double, acuity: Int, capacity: Int, status: PrimaryRoundingProfileStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.sequence = sequence
            self.discount = discount
            self.cost = cost
            self.budget = budget
            self.patientRef = patientRef
            self.copay = copay
            self.acuity = acuity
            self.capacity = capacity
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

        func canMoveTo(_ next: PrimaryRoundingProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryRoundingProfileStatus.closed
            case .suspended:
                return next == PrimaryRoundingProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryRoundingProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary rounding profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary rounding profile") \(code)"
        }

        func projectedValue() -> Double {
            return (budget * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRoundingProfile {
            return PrimaryRoundingProfile(
                code: code,
                title: title,
                retries: retries,
                sequence: sequence,
                discount: discount,
                cost: cost,
                budget: budget,
                patientRef: patientRef,
                copay: copay,
                acuity: acuity,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary rounding profile in status draft.
    static func newPrimaryRoundingProfile(_ code: String, title: String) -> PrimaryRoundingProfile {
        return PrimaryRoundingProfile(
            code: code,
            title: title,
            retries: 0,
            sequence: 0,
            discount: 0.0,
            cost: 0.0,
            budget: 0.0,
            patientRef: "",
            copay: 0.0,
            acuity: 0,
            capacity: 0,
            status: PrimaryRoundingProfileStatus.draft
        )
    }
}
