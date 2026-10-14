import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered network digest is in its life cycle.
    enum TieredNetworkDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One tiered network digest, with what the planners need to act on it.
    final class TieredNetworkDigest {
        var code: String
        var name: String
        var channel: String
        var acuity: Int
        var score: Double
        var dosageMg: Double
        var startsAt: Int
        var payer: String
        var diagnosisCode: String
        var status: TieredNetworkDigestStatus

        init(code: String, name: String, channel: String, acuity: Int, score: Double, dosageMg: Double, startsAt: Int, payer: String, diagnosisCode: String, status: TieredNetworkDigestStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.acuity = acuity
            self.score = score
            self.dosageMg = dosageMg
            self.startsAt = startsAt
            self.payer = payer
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: TieredNetworkDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredNetworkDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered network digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return ((score - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> TieredNetworkDigest {
            return TieredNetworkDigest(
                code: code,
                name: name,
                channel: channel,
                acuity: acuity,
                score: score,
                dosageMg: dosageMg,
                startsAt: startsAt,
                payer: payer,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a tiered network digest in status created.
    static func newTieredNetworkDigest(_ code: String, name: String) -> TieredNetworkDigest {
        return TieredNetworkDigest(
            code: code,
            name: name,
            channel: "",
            acuity: 0,
            score: 0.0,
            dosageMg: 0.0,
            startsAt: 0,
            payer: "",
            diagnosisCode: "",
            status: TieredNetworkDigestStatus.created
        )
    }
}
