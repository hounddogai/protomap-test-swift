import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral audit is in its life cycle.
    enum ReferralAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One referral audit, with what the planners need to act on it.
    final class ReferralAudit {
        var code: String
        var name: String
        var diagnosisCode: String
        var version: Int
        var channel: String
        var status: ReferralAuditStatus

        init(code: String, name: String, diagnosisCode: String, version: Int, channel: String, status: ReferralAuditStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.version = version
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralAuditStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ReferralAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> ReferralAudit {
            return ReferralAudit(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                version: version,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a referral audit in status proposed.
    static func newReferralAudit(_ code: String, name: String) -> ReferralAudit {
        return ReferralAudit(
            code: code,
            name: name,
            diagnosisCode: "",
            version: 0,
            channel: "",
            status: ReferralAuditStatus.proposed
        )
    }
}
