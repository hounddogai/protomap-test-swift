import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy proposal is in its life cycle.
    enum ProxyProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A proxy proposal. Its code is unique within a tenant.
    final class ProxyProposal {
        var code: String
        var name: String
        var retries: Int
        var capacity: Int
        var facility: String
        var minimum: Double
        var status: ProxyProposalStatus

        init(code: String, name: String, retries: Int, capacity: Int, facility: String, minimum: Double, status: ProxyProposalStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.capacity = capacity
            self.facility = facility
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ProxyProposalStatus.archived
            case .resolved:
                return next == ProxyProposalStatus.reopened || next == ProxyProposalStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ProxyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedVolume() -> Double {
            return ((minimum + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyProposal {
            return ProxyProposal(
                code: code,
                name: name,
                retries: retries,
                capacity: capacity,
                facility: facility,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy proposal in status open.
    static func newProxyProposal(_ code: String, name: String) -> ProxyProposal {
        return ProxyProposal(
            code: code,
            name: name,
            retries: 0,
            capacity: 0,
            facility: "",
            minimum: 0.0,
            status: ProxyProposalStatus.`open`
        )
    }
}
