import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network claim is in its life cycle.
    enum NetworkClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A network claim. Its code is unique within a tenant.
    final class NetworkClaim {
        var code: String
        var title: String
        var score: Double
        var expiresAt: Int
        var currency: String
        var status: NetworkClaimStatus

        init(code: String, title: String, score: Double, expiresAt: Int, currency: String, status: NetworkClaimStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.expiresAt = expiresAt
            self.currency = currency
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

        func canMoveTo(_ next: NetworkClaimStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == NetworkClaimStatus.suspended || next == NetworkClaimStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: NetworkClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("network claim") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(expiresAt) - score) * 100).rounded() / 100
        }

        func copyValue() -> NetworkClaim {
            return NetworkClaim(
                code: code,
                title: title,
                score: score,
                expiresAt: expiresAt,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a network claim in status draft.
    static func newNetworkClaim(_ code: String, title: String) -> NetworkClaim {
        return NetworkClaim(
            code: code,
            title: title,
            score: 0.0,
            expiresAt: 0,
            currency: "",
            status: NetworkClaimStatus.draft
        )
    }
}
