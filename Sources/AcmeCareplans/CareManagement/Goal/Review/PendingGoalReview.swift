import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending goal review is in its life cycle.
    enum PendingGoalReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending goal review. Its code is unique within a tenant.
    final class PendingGoalReview {
        var code: String
        var label: String
        var category: String
        var allergy: String
        var capacity: Int
        var channel: String
        var reviewer: String
        var attributes: [String: String]
        var source: String
        var retries: Int
        var status: PendingGoalReviewStatus

        init(code: String, label: String, category: String, allergy: String, capacity: Int, channel: String, reviewer: String, attributes: [String: String], source: String, retries: Int, status: PendingGoalReviewStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.allergy = allergy
            self.capacity = capacity
            self.channel = channel
            self.reviewer = reviewer
            self.attributes = attributes
            self.source = source
            self.retries = retries
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

        func canMoveTo(_ next: PendingGoalReviewStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingGoalReviewStatus.inReview || next == PendingGoalReviewStatus.resolved
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingGoalReviewStatus.archived
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

        func moveTo(_ next: PendingGoalReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending goal review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending goal review") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveExposure() -> Double {
            return ((Double(retries) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingGoalReview {
            return PendingGoalReview(
                code: code,
                label: label,
                category: category,
                allergy: allergy,
                capacity: capacity,
                channel: channel,
                reviewer: reviewer,
                attributes: attributes,
                source: source,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending goal review in status open.
    static func newPendingGoalReview(_ code: String, label: String) -> PendingGoalReview {
        return PendingGoalReview(
            code: code,
            label: label,
            category: "",
            allergy: "",
            capacity: 0,
            channel: "",
            reviewer: "",
            attributes: [:],
            source: "",
            retries: 0,
            status: PendingGoalReviewStatus.`open`
        )
    }
}
