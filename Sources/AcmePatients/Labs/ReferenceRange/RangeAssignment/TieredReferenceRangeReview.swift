import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered reference range review is in its life cycle.
    enum TieredReferenceRangeReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a tiered reference range review and its current status.
    final class TieredReferenceRangeReview {
        var code: String
        var label: String
        var minimum: Double
        var graceDays: Int
        var reviewer: String
        var endsAt: Int
        var contactEmail: String
        var patientRef: String
        var encounterID: String
        var approved: Bool
        var status: TieredReferenceRangeReviewStatus

        init(code: String, label: String, minimum: Double, graceDays: Int, reviewer: String, endsAt: Int, contactEmail: String, patientRef: String, encounterID: String, approved: Bool, status: TieredReferenceRangeReviewStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.graceDays = graceDays
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.encounterID = encounterID
            self.approved = approved
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

        func canMoveTo(_ next: TieredReferenceRangeReviewStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
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
                return next == TieredReferenceRangeReviewStatus.completed
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

        func moveTo(_ next: TieredReferenceRangeReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered reference range review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("tiered reference range review") \(code)"
        }

        func netValue() -> Double {
            return (minimum * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredReferenceRangeReview {
            return TieredReferenceRangeReview(
                code: code,
                label: label,
                minimum: minimum,
                graceDays: graceDays,
                reviewer: reviewer,
                endsAt: endsAt,
                contactEmail: contactEmail,
                patientRef: patientRef,
                encounterID: encounterID,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered reference range review in status planned.
    static func newTieredReferenceRangeReview(_ code: String, label: String) -> TieredReferenceRangeReview {
        return TieredReferenceRangeReview(
            code: code,
            label: label,
            minimum: 0.0,
            graceDays: 0,
            reviewer: "",
            endsAt: 0,
            contactEmail: "",
            patientRef: "",
            encounterID: "",
            approved: false,
            status: TieredReferenceRangeReviewStatus.planned
        )
    }
}
