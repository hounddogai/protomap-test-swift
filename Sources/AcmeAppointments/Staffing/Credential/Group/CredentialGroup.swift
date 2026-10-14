import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential group is in its life cycle.
    enum CredentialGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A credential group. Its code is unique within a tenant.
    final class CredentialGroup {
        var code: String
        var name: String
        var bed: String
        var minimum: Double
        var channel: String
        var copay: Double
        var ownerID: String
        var approved: Bool
        var discount: Double
        var locale: String
        var status: CredentialGroupStatus

        init(code: String, name: String, bed: String, minimum: Double, channel: String, copay: Double, ownerID: String, approved: Bool, discount: Double, locale: String, status: CredentialGroupStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.minimum = minimum
            self.channel = channel
            self.copay = copay
            self.ownerID = ownerID
            self.approved = approved
            self.discount = discount
            self.locale = locale
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

        func canMoveTo(_ next: CredentialGroupStatus) -> Bool {
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
                return next == CredentialGroupStatus.archived
            case .resolved:
                return next == CredentialGroupStatus.reopened || next == CredentialGroupStatus.archived
            case .reopened:
                return next == CredentialGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((discount + minimum) * 100).rounded() / 100
        }

        func copyValue() -> CredentialGroup {
            return CredentialGroup(
                code: code,
                name: name,
                bed: bed,
                minimum: minimum,
                channel: channel,
                copay: copay,
                ownerID: ownerID,
                approved: approved,
                discount: discount,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a credential group in status open.
    static func newCredentialGroup(_ code: String, name: String) -> CredentialGroup {
        return CredentialGroup(
            code: code,
            name: name,
            bed: "",
            minimum: 0.0,
            channel: "",
            copay: 0.0,
            ownerID: "",
            approved: false,
            discount: 0.0,
            locale: "",
            status: CredentialGroupStatus.`open`
        )
    }
}
