import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback credential window is in its life cycle.
    enum FallbackCredentialWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback credential window. Its code is unique within a tenant.
    final class FallbackCredentialWindow {
        var code: String
        var label: String
        var timezone: String
        var threshold: Double
        var startsAt: Int
        var approved: Bool
        var ownerID: String
        var contactEmail: String
        var margin: Double
        var revision: Int
        var status: FallbackCredentialWindowStatus

        init(code: String, label: String, timezone: String, threshold: Double, startsAt: Int, approved: Bool, ownerID: String, contactEmail: String, margin: Double, revision: Int, status: FallbackCredentialWindowStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.threshold = threshold
            self.startsAt = startsAt
            self.approved = approved
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.margin = margin
            self.revision = revision
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

        func canMoveTo(_ next: FallbackCredentialWindowStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FallbackCredentialWindowStatus.resolved
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

        func moveTo(_ next: FallbackCredentialWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback credential window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netTotal() -> Double {
            return ((Double(revision) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCredentialWindow {
            return FallbackCredentialWindow(
                code: code,
                label: label,
                timezone: timezone,
                threshold: threshold,
                startsAt: startsAt,
                approved: approved,
                ownerID: ownerID,
                contactEmail: contactEmail,
                margin: margin,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback credential window in status open.
    static func newFallbackCredentialWindow(_ code: String, label: String) -> FallbackCredentialWindow {
        return FallbackCredentialWindow(
            code: code,
            label: label,
            timezone: "",
            threshold: 0.0,
            startsAt: 0,
            approved: false,
            ownerID: "",
            contactEmail: "",
            margin: 0.0,
            revision: 0,
            status: FallbackCredentialWindowStatus.`open`
        )
    }
}
