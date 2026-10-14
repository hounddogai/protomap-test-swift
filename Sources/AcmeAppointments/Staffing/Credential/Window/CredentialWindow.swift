import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential window is in its life cycle.
    enum CredentialWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A credential window. Its code is unique within a tenant.
    final class CredentialWindow {
        var code: String
        var label: String
        var cost: Double
        var timezone: String
        var discount: Double
        var description: String
        var segment: String
        var clinicianID: String
        var tags: [String]
        var status: CredentialWindowStatus

        init(code: String, label: String, cost: Double, timezone: String, discount: Double, description: String, segment: String, clinicianID: String, tags: [String], status: CredentialWindowStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.timezone = timezone
            self.discount = discount
            self.description = description
            self.segment = segment
            self.clinicianID = clinicianID
            self.tags = tags
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

        func canMoveTo(_ next: CredentialWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == CredentialWindowStatus.ready
            case .warming:
                return next == CredentialWindowStatus.ready || next == CredentialWindowStatus.stopped
            case .ready:
                return next == CredentialWindowStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CredentialWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("credential window") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((discount + cost) * 100).rounded() / 100
        }

        func copyValue() -> CredentialWindow {
            return CredentialWindow(
                code: code,
                label: label,
                cost: cost,
                timezone: timezone,
                discount: discount,
                description: description,
                segment: segment,
                clinicianID: clinicianID,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a credential window in status idle.
    static func newCredentialWindow(_ code: String, label: String) -> CredentialWindow {
        return CredentialWindow(
            code: code,
            label: label,
            cost: 0.0,
            timezone: "",
            discount: 0.0,
            description: "",
            segment: "",
            clinicianID: "",
            tags: [],
            status: CredentialWindowStatus.idle
        )
    }
}
