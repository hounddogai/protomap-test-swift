import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization tier is in its life cycle.
    enum AuthorizationTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A authorization tier as the authorization team keeps it.
    final class AuthorizationTier {
        var code: String
        var title: String
        var acuity: Int
        var unit: String
        var score: Double
        var capacity: Int
        var amount: Double
        var label: String
        var sequence: Int
        var status: AuthorizationTierStatus

        init(code: String, title: String, acuity: Int, unit: String, score: Double, capacity: Int, amount: Double, label: String, sequence: Int, status: AuthorizationTierStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.unit = unit
            self.score = score
            self.capacity = capacity
            self.amount = amount
            self.label = label
            self.sequence = sequence
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

        func canMoveTo(_ next: AuthorizationTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AuthorizationTierStatus.published || next == AuthorizationTierStatus.retired
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

        func moveTo(_ next: AuthorizationTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return ((Double(acuity) - score) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationTier {
            return AuthorizationTier(
                code: code,
                title: title,
                acuity: acuity,
                unit: unit,
                score: score,
                capacity: capacity,
                amount: amount,
                label: label,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a authorization tier in status created.
    static func newAuthorizationTier(_ code: String, title: String) -> AuthorizationTier {
        return AuthorizationTier(
            code: code,
            title: title,
            acuity: 0,
            unit: "",
            score: 0.0,
            capacity: 0,
            amount: 0.0,
            label: "",
            sequence: 0,
            status: AuthorizationTierStatus.created
        )
    }
}
