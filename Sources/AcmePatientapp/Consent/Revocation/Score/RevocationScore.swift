import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation score is in its life cycle.
    enum RevocationScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A revocation score as the revocation team keeps it.
    final class RevocationScore {
        var code: String
        var label: String
        var visible: Bool
        var budget: Double
        var expiresAt: Int
        var updatedAt: Int
        var externalRef: String
        var durationMinutes: Int
        var status: RevocationScoreStatus

        init(code: String, label: String, visible: Bool, budget: Double, expiresAt: Int, updatedAt: Int, externalRef: String, durationMinutes: Int, status: RevocationScoreStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.budget = budget
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationScoreStatus) -> Bool {
            switch status {
            case .requested:
                return next == RevocationScoreStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RevocationScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return ((Double(durationMinutes) - budget) * 100).rounded() / 100
        }

        func copyValue() -> RevocationScore {
            return RevocationScore(
                code: code,
                label: label,
                visible: visible,
                budget: budget,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                externalRef: externalRef,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a revocation score in status requested.
    static func newRevocationScore(_ code: String, label: String) -> RevocationScore {
        return RevocationScore(
            code: code,
            label: label,
            visible: false,
            budget: 0.0,
            expiresAt: 0,
            updatedAt: 0,
            externalRef: "",
            durationMinutes: 0,
            status: RevocationScoreStatus.requested
        )
    }
}
