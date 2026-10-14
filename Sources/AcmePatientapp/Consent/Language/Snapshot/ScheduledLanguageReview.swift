import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled language review is in its life cycle.
    enum ScheduledLanguageReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled language review. Its code is unique within a tenant.
    final class ScheduledLanguageReview {
        var code: String
        var label: String
        var attributes: [String: String]
        var name: String
        var reviewer: String
        var category: String
        var capacity: Int
        var contactEmail: String
        var status: ScheduledLanguageReviewStatus

        init(code: String, label: String, attributes: [String: String], name: String, reviewer: String, category: String, capacity: Int, contactEmail: String, status: ScheduledLanguageReviewStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.name = name
            self.reviewer = reviewer
            self.category = category
            self.capacity = capacity
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledLanguageReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledLanguageReviewStatus.draining || next == ScheduledLanguageReviewStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ScheduledLanguageReviewStatus.draining || next == ScheduledLanguageReviewStatus.stopped
            case .draining:
                return next == ScheduledLanguageReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledLanguageReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled language review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> ScheduledLanguageReview {
            return ScheduledLanguageReview(
                code: code,
                label: label,
                attributes: attributes,
                name: name,
                reviewer: reviewer,
                category: category,
                capacity: capacity,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a scheduled language review in status idle.
    static func newScheduledLanguageReview(_ code: String, label: String) -> ScheduledLanguageReview {
        return ScheduledLanguageReview(
            code: code,
            label: label,
            attributes: [:],
            name: "",
            reviewer: "",
            category: "",
            capacity: 0,
            contactEmail: "",
            status: ScheduledLanguageReviewStatus.idle
        )
    }
}
