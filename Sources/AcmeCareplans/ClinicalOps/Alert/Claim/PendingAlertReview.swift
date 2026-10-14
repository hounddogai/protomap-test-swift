import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending alert review is in its life cycle.
    enum PendingAlertReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending alert review as the alert team keeps it.
    final class PendingAlertReview {
        var code: String
        var label: String
        var reviewer: String
        var approved: Bool
        var ownerID: String
        var acuity: Int
        var quantity: Int
        var category: String
        var encounterID: String
        var name: String
        var timezone: String
        var status: PendingAlertReviewStatus

        init(code: String, label: String, reviewer: String, approved: Bool, ownerID: String, acuity: Int, quantity: Int, category: String, encounterID: String, name: String, timezone: String, status: PendingAlertReviewStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.approved = approved
            self.ownerID = ownerID
            self.acuity = acuity
            self.quantity = quantity
            self.category = category
            self.encounterID = encounterID
            self.name = name
            self.timezone = timezone
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

        func canMoveTo(_ next: PendingAlertReviewStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingAlertReviewStatus.resolved || next == PendingAlertReviewStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingAlertReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending alert review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending alert review") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(acuity) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingAlertReview {
            return PendingAlertReview(
                code: code,
                label: label,
                reviewer: reviewer,
                approved: approved,
                ownerID: ownerID,
                acuity: acuity,
                quantity: quantity,
                category: category,
                encounterID: encounterID,
                name: name,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending alert review in status open.
    static func newPendingAlertReview(_ code: String, label: String) -> PendingAlertReview {
        return PendingAlertReview(
            code: code,
            label: label,
            reviewer: "",
            approved: false,
            ownerID: "",
            acuity: 0,
            quantity: 0,
            category: "",
            encounterID: "",
            name: "",
            timezone: "",
            status: PendingAlertReviewStatus.`open`
        )
    }
}
