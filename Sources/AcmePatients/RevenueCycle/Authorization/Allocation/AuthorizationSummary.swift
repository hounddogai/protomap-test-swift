import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization summary is in its life cycle.
    enum AuthorizationSummaryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a authorization summary and its current status.
    final class AuthorizationSummary {
        var code: String
        var title: String
        var phone: String
        var facility: String
        var attributes: [String: String]
        var ward: String
        var discount: Double
        var priority: Int
        var limit: Int
        var status: AuthorizationSummaryStatus

        init(code: String, title: String, phone: String, facility: String, attributes: [String: String], ward: String, discount: Double, priority: Int, limit: Int, status: AuthorizationSummaryStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.facility = facility
            self.attributes = attributes
            self.ward = ward
            self.discount = discount
            self.priority = priority
            self.limit = limit
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

        func canMoveTo(_ next: AuthorizationSummaryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AuthorizationSummaryStatus.resolved || next == AuthorizationSummaryStatus.reopened
            case .inReview:
                return next == AuthorizationSummaryStatus.reopened
            case .resolved:
                return next == AuthorizationSummaryStatus.reopened || next == AuthorizationSummaryStatus.archived
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

        func moveTo(_ next: AuthorizationSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func netVolume() -> Double {
            return ((discount + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationSummary {
            return AuthorizationSummary(
                code: code,
                title: title,
                phone: phone,
                facility: facility,
                attributes: attributes,
                ward: ward,
                discount: discount,
                priority: priority,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a authorization summary in status open.
    static func newAuthorizationSummary(_ code: String, title: String) -> AuthorizationSummary {
        return AuthorizationSummary(
            code: code,
            title: title,
            phone: "",
            facility: "",
            attributes: [:],
            ward: "",
            discount: 0.0,
            priority: 0,
            limit: 0,
            status: AuthorizationSummaryStatus.`open`
        )
    }
}
