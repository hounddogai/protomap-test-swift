import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped proxy proposal is in its life cycle.
    enum CappedProxyProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped proxy proposal as the proxy team keeps it.
    final class CappedProxyProposal {
        var code: String
        var name: String
        var phone: String
        var acuity: Int
        var channel: String
        var status: CappedProxyProposalStatus

        init(code: String, name: String, phone: String, acuity: Int, channel: String, status: CappedProxyProposalStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.acuity = acuity
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

        func canMoveTo(_ next: CappedProxyProposalStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
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

        func moveTo(_ next: CappedProxyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped proxy proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> CappedProxyProposal {
            return CappedProxyProposal(
                code: code,
                name: name,
                phone: phone,
                acuity: acuity,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped proxy proposal in status requested.
    static func newCappedProxyProposal(_ code: String, name: String) -> CappedProxyProposal {
        return CappedProxyProposal(
            code: code,
            name: name,
            phone: "",
            acuity: 0,
            channel: "",
            status: CappedProxyProposalStatus.requested
        )
    }
}
