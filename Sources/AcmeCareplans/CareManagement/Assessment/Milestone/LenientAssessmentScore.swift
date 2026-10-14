import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient assessment score is in its life cycle.
    enum LenientAssessmentScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient assessment score. Its code is unique within a tenant.
    final class LenientAssessmentScore {
        var code: String
        var name: String
        var capacity: Int
        var cost: Double
        var margin: Double
        var copay: Double
        var clinicianID: String
        var sequence: Int
        var ratio: Double
        var score: Double
        var discount: Double
        var status: LenientAssessmentScoreStatus

        init(code: String, name: String, capacity: Int, cost: Double, margin: Double, copay: Double, clinicianID: String, sequence: Int, ratio: Double, score: Double, discount: Double, status: LenientAssessmentScoreStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.cost = cost
            self.margin = margin
            self.copay = copay
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.ratio = ratio
            self.score = score
            self.discount = discount
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

        func canMoveTo(_ next: LenientAssessmentScoreStatus) -> Bool {
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
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientAssessmentScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient assessment score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient assessment score") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(sequence) - score) * 100).rounded() / 100
        }

        func copyValue() -> LenientAssessmentScore {
            return LenientAssessmentScore(
                code: code,
                name: name,
                capacity: capacity,
                cost: cost,
                margin: margin,
                copay: copay,
                clinicianID: clinicianID,
                sequence: sequence,
                ratio: ratio,
                score: score,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient assessment score in status draft.
    static func newLenientAssessmentScore(_ code: String, name: String) -> LenientAssessmentScore {
        return LenientAssessmentScore(
            code: code,
            name: name,
            capacity: 0,
            cost: 0.0,
            margin: 0.0,
            copay: 0.0,
            clinicianID: "",
            sequence: 0,
            ratio: 0.0,
            score: 0.0,
            discount: 0.0,
            status: LenientAssessmentScoreStatus.draft
        )
    }
}
