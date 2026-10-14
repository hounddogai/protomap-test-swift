import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary outreach review is in its life cycle.
    enum PrimaryOutreachReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One primary outreach review, with what the planners need to act on it.
    final class PrimaryOutreachReview {
        var code: String
        var label: String
        var attempts: Int
        var title: String
        var description: String
        var updatedAt: Int
        var cost: Double
        var margin: Double
        var timezone: String
        var reviewer: String
        var status: PrimaryOutreachReviewStatus

        init(code: String, label: String, attempts: Int, title: String, description: String, updatedAt: Int, cost: Double, margin: Double, timezone: String, reviewer: String, status: PrimaryOutreachReviewStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.title = title
            self.description = description
            self.updatedAt = updatedAt
            self.cost = cost
            self.margin = margin
            self.timezone = timezone
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryOutreachReviewStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryOutreachReviewStatus.inReview || next == PrimaryOutreachReviewStatus.archived
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryOutreachReviewStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryOutreachReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary outreach review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return (cost * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOutreachReview {
            return PrimaryOutreachReview(
                code: code,
                label: label,
                attempts: attempts,
                title: title,
                description: description,
                updatedAt: updatedAt,
                cost: cost,
                margin: margin,
                timezone: timezone,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary outreach review in status open.
    static func newPrimaryOutreachReview(_ code: String, label: String) -> PrimaryOutreachReview {
        return PrimaryOutreachReview(
            code: code,
            label: label,
            attempts: 0,
            title: "",
            description: "",
            updatedAt: 0,
            cost: 0.0,
            margin: 0.0,
            timezone: "",
            reviewer: "",
            status: PrimaryOutreachReviewStatus.`open`
        )
    }
}
