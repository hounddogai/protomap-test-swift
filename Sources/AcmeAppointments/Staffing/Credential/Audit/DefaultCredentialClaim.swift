import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default credential claim is in its life cycle.
    enum DefaultCredentialClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A default credential claim as the credential team keeps it.
    final class DefaultCredentialClaim {
        var code: String
        var title: String
        var amount: Double
        var dosageMg: Double
        var minimum: Double
        var channel: String
        var status: DefaultCredentialClaimStatus

        init(code: String, title: String, amount: Double, dosageMg: Double, minimum: Double, channel: String, status: DefaultCredentialClaimStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultCredentialClaimStatus) -> Bool {
            switch status {
            case .draft:
                return next == DefaultCredentialClaimStatus.pending || next == DefaultCredentialClaimStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DefaultCredentialClaimStatus.suspended || next == DefaultCredentialClaimStatus.closed
            case .suspended:
                return next == DefaultCredentialClaimStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCredentialClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default credential claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return ((minimum - amount) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCredentialClaim {
            return DefaultCredentialClaim(
                code: code,
                title: title,
                amount: amount,
                dosageMg: dosageMg,
                minimum: minimum,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default credential claim in status draft.
    static func newDefaultCredentialClaim(_ code: String, title: String) -> DefaultCredentialClaim {
        return DefaultCredentialClaim(
            code: code,
            title: title,
            amount: 0.0,
            dosageMg: 0.0,
            minimum: 0.0,
            channel: "",
            status: DefaultCredentialClaimStatus.draft
        )
    }
}
