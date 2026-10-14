import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy policy is in its life cycle.
    enum ProxyPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a proxy policy and its current status.
    final class ProxyPolicy {
        var code: String
        var label: String
        var locale: String
        var visible: Bool
        var maximum: Double
        var revision: Int
        var amount: Double
        var sequence: Int
        var expiresAt: Int
        var ward: String
        var region: String
        var status: ProxyPolicyStatus

        init(code: String, label: String, locale: String, visible: Bool, maximum: Double, revision: Int, amount: Double, sequence: Int, expiresAt: Int, ward: String, region: String, status: ProxyPolicyStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.visible = visible
            self.maximum = maximum
            self.revision = revision
            self.amount = amount
            self.sequence = sequence
            self.expiresAt = expiresAt
            self.ward = ward
            self.region = region
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

        func canMoveTo(_ next: ProxyPolicyStatus) -> Bool {
            switch status {
            case .requested:
                return next == ProxyPolicyStatus.revoked
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: ProxyPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("proxy policy") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(sequence) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> ProxyPolicy {
            return ProxyPolicy(
                code: code,
                label: label,
                locale: locale,
                visible: visible,
                maximum: maximum,
                revision: revision,
                amount: amount,
                sequence: sequence,
                expiresAt: expiresAt,
                ward: ward,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a proxy policy in status requested.
    static func newProxyPolicy(_ code: String, label: String) -> ProxyPolicy {
        return ProxyPolicy(
            code: code,
            label: label,
            locale: "",
            visible: false,
            maximum: 0.0,
            revision: 0,
            amount: 0.0,
            sequence: 0,
            expiresAt: 0,
            ward: "",
            region: "",
            status: ProxyPolicyStatus.requested
        )
    }
}
