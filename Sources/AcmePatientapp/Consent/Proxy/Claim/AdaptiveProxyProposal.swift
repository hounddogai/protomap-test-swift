import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive proxy proposal is in its life cycle.
    enum AdaptiveProxyProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a adaptive proxy proposal and its current status.
    final class AdaptiveProxyProposal {
        var code: String
        var name: String
        var acuity: Int
        var ward: String
        var archived: Bool
        var capacity: Int
        var status: AdaptiveProxyProposalStatus

        init(code: String, name: String, acuity: Int, ward: String, archived: Bool, capacity: Int, status: AdaptiveProxyProposalStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.ward = ward
            self.archived = archived
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveProxyProposalStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveProxyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive proxy proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return (Double(capacity) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveProxyProposal {
            return AdaptiveProxyProposal(
                code: code,
                name: name,
                acuity: acuity,
                ward: ward,
                archived: archived,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive proxy proposal in status new.
    static func newAdaptiveProxyProposal(_ code: String, name: String) -> AdaptiveProxyProposal {
        return AdaptiveProxyProposal(
            code: code,
            name: name,
            acuity: 0,
            ward: "",
            archived: false,
            capacity: 0,
            status: AdaptiveProxyProposalStatus.new
        )
    }
}
