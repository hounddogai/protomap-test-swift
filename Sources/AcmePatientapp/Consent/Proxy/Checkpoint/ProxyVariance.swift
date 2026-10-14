import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy variance is in its life cycle.
    enum ProxyVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One proxy variance, with what the planners need to act on it.
    final class ProxyVariance {
        var code: String
        var label: String
        var active: Bool
        var channel: String
        var locale: String
        var diagnosisCode: String
        var payer: String
        var revision: Int
        var score: Double
        var status: ProxyVarianceStatus

        init(code: String, label: String, active: Bool, channel: String, locale: String, diagnosisCode: String, payer: String, revision: Int, score: Double, status: ProxyVarianceStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.channel = channel
            self.locale = locale
            self.diagnosisCode = diagnosisCode
            self.payer = payer
            self.revision = revision
            self.score = score
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

        func canMoveTo(_ next: ProxyVarianceStatus) -> Bool {
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
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ProxyVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveLoad() -> Double {
            return (score * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> ProxyVariance {
            return ProxyVariance(
                code: code,
                label: label,
                active: active,
                channel: channel,
                locale: locale,
                diagnosisCode: diagnosisCode,
                payer: payer,
                revision: revision,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a proxy variance in status requested.
    static func newProxyVariance(_ code: String, label: String) -> ProxyVariance {
        return ProxyVariance(
            code: code,
            label: label,
            active: false,
            channel: "",
            locale: "",
            diagnosisCode: "",
            payer: "",
            revision: 0,
            score: 0.0,
            status: ProxyVarianceStatus.requested
        )
    }
}
