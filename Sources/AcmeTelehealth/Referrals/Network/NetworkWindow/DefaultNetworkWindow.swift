import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default network window is in its life cycle.
    enum DefaultNetworkWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A default network window. Its code is unique within a tenant.
    final class DefaultNetworkWindow {
        var code: String
        var label: String
        var ownerID: String
        var contactEmail: String
        var active: Bool
        var revision: Int
        var discount: Double
        var retries: Int
        var title: String
        var status: DefaultNetworkWindowStatus

        init(code: String, label: String, ownerID: String, contactEmail: String, active: Bool, revision: Int, discount: Double, retries: Int, title: String, status: DefaultNetworkWindowStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.active = active
            self.revision = revision
            self.discount = discount
            self.retries = retries
            self.title = title
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

        func canMoveTo(_ next: DefaultNetworkWindowStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultNetworkWindowStatus.inReview || next == DefaultNetworkWindowStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DefaultNetworkWindowStatus.archived
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

        func moveTo(_ next: DefaultNetworkWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default network window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("default network window") \(code)"
        }

        func adjustedLoad() -> Double {
            return (discount * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> DefaultNetworkWindow {
            return DefaultNetworkWindow(
                code: code,
                label: label,
                ownerID: ownerID,
                contactEmail: contactEmail,
                active: active,
                revision: revision,
                discount: discount,
                retries: retries,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default network window in status open.
    static func newDefaultNetworkWindow(_ code: String, label: String) -> DefaultNetworkWindow {
        return DefaultNetworkWindow(
            code: code,
            label: label,
            ownerID: "",
            contactEmail: "",
            active: false,
            revision: 0,
            discount: 0.0,
            retries: 0,
            title: "",
            status: DefaultNetworkWindowStatus.`open`
        )
    }
}
