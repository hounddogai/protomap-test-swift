import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census review is in its life cycle.
    enum CensusReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One census review, with what the planners need to act on it.
    final class CensusReview {
        var code: String
        var name: String
        var label: String
        var durationMinutes: Int
        var procedureCode: String
        var weight: Double
        var status: CensusReviewStatus

        init(code: String, name: String, label: String, durationMinutes: Int, procedureCode: String, weight: Double, status: CensusReviewStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.durationMinutes = durationMinutes
            self.procedureCode = procedureCode
            self.weight = weight
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

        func canMoveTo(_ next: CensusReviewStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
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
                return next == CensusReviewStatus.closed
            case .suspended:
                return next == CensusReviewStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return (Double(durationMinutes) * weight * 100).rounded() / 100
        }

        func copyValue() -> CensusReview {
            return CensusReview(
                code: code,
                name: name,
                label: label,
                durationMinutes: durationMinutes,
                procedureCode: procedureCode,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a census review in status draft.
    static func newCensusReview(_ code: String, name: String) -> CensusReview {
        return CensusReview(
            code: code,
            name: name,
            label: "",
            durationMinutes: 0,
            procedureCode: "",
            weight: 0.0,
            status: CensusReviewStatus.draft
        )
    }
}
