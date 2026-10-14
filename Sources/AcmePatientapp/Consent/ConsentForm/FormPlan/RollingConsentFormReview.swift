import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling consent form review is in its life cycle.
    enum RollingConsentFormReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling consent form review. Its code is unique within a tenant.
    final class RollingConsentFormReview {
        var code: String
        var title: String
        var contactEmail: String
        var windowDays: Int
        var ownerID: String
        var quantity: Int
        var category: String
        var priority: Int
        var status: RollingConsentFormReviewStatus

        init(code: String, title: String, contactEmail: String, windowDays: Int, ownerID: String, quantity: Int, category: String, priority: Int, status: RollingConsentFormReviewStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.windowDays = windowDays
            self.ownerID = ownerID
            self.quantity = quantity
            self.category = category
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingConsentFormReviewStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RollingConsentFormReviewStatus.published || next == RollingConsentFormReviewStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingConsentFormReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling consent form review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((Double(priority) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RollingConsentFormReview {
            return RollingConsentFormReview(
                code: code,
                title: title,
                contactEmail: contactEmail,
                windowDays: windowDays,
                ownerID: ownerID,
                quantity: quantity,
                category: category,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling consent form review in status created.
    static func newRollingConsentFormReview(_ code: String, title: String) -> RollingConsentFormReview {
        return RollingConsentFormReview(
            code: code,
            title: title,
            contactEmail: "",
            windowDays: 0,
            ownerID: "",
            quantity: 0,
            category: "",
            priority: 0,
            status: RollingConsentFormReviewStatus.created
        )
    }
}
