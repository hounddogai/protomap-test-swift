import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict recall review is in its life cycle.
    enum StrictRecallReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict recall review. Its code is unique within a tenant.
    final class StrictRecallReview {
        var code: String
        var label: String
        var country: String
        var summary: String
        var endsAt: Int
        var clinicianID: String
        var dosageMg: Double
        var status: StrictRecallReviewStatus

        init(code: String, label: String, country: String, summary: String, endsAt: Int, clinicianID: String, dosageMg: Double, status: StrictRecallReviewStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.summary = summary
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: StrictRecallReviewStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictRecallReviewStatus.inProgress || next == StrictRecallReviewStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StrictRecallReviewStatus.completed
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

        func moveTo(_ next: StrictRecallReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict recall review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return (dosageMg * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> StrictRecallReview {
            return StrictRecallReview(
                code: code,
                label: label,
                country: country,
                summary: summary,
                endsAt: endsAt,
                clinicianID: clinicianID,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a strict recall review in status planned.
    static func newStrictRecallReview(_ code: String, label: String) -> StrictRecallReview {
        return StrictRecallReview(
            code: code,
            label: label,
            country: "",
            summary: "",
            endsAt: 0,
            clinicianID: "",
            dosageMg: 0.0,
            status: StrictRecallReviewStatus.planned
        )
    }
}
