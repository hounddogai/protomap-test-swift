import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution review is in its life cycle.
    enum SubstitutionReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A substitution review. Its code is unique within a tenant.
    final class SubstitutionReview {
        var code: String
        var title: String
        var ratio: Double
        var allergy: String
        var dosageMg: Double
        var sequence: Int
        var status: SubstitutionReviewStatus

        init(code: String, title: String, ratio: Double, allergy: String, dosageMg: Double, sequence: Int, status: SubstitutionReviewStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.allergy = allergy
            self.dosageMg = dosageMg
            self.sequence = sequence
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

        func canMoveTo(_ next: SubstitutionReviewStatus) -> Bool {
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
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SubstitutionReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return (Double(sequence) * ratio * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionReview {
            return SubstitutionReview(
                code: code,
                title: title,
                ratio: ratio,
                allergy: allergy,
                dosageMg: dosageMg,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution review in status planned.
    static func newSubstitutionReview(_ code: String, title: String) -> SubstitutionReview {
        return SubstitutionReview(
            code: code,
            title: title,
            ratio: 0.0,
            allergy: "",
            dosageMg: 0.0,
            sequence: 0,
            status: SubstitutionReviewStatus.planned
        )
    }
}
