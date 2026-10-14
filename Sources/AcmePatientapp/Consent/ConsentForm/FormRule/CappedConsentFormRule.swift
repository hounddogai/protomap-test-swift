import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped consent form rule is in its life cycle.
    enum CappedConsentFormRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped consent form rule as the consent form team keeps it.
    final class CappedConsentFormRule {
        var code: String
        var name: String
        var sequence: Int
        var payer: String
        var threshold: Double
        var ceiling: Double
        var channel: String
        var status: CappedConsentFormRuleStatus

        init(code: String, name: String, sequence: Int, payer: String, threshold: Double, ceiling: Double, channel: String, status: CappedConsentFormRuleStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.payer = payer
            self.threshold = threshold
            self.ceiling = ceiling
            self.channel = channel
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

        func canMoveTo(_ next: CappedConsentFormRuleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CappedConsentFormRuleStatus.revoked || next == CappedConsentFormRuleStatus.expired
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

        func moveTo(_ next: CappedConsentFormRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped consent form rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return ((Double(sequence) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CappedConsentFormRule {
            return CappedConsentFormRule(
                code: code,
                name: name,
                sequence: sequence,
                payer: payer,
                threshold: threshold,
                ceiling: ceiling,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped consent form rule in status requested.
    static func newCappedConsentFormRule(_ code: String, name: String) -> CappedConsentFormRule {
        return CappedConsentFormRule(
            code: code,
            name: name,
            sequence: 0,
            payer: "",
            threshold: 0.0,
            ceiling: 0.0,
            channel: "",
            status: CappedConsentFormRuleStatus.requested
        )
    }
}
