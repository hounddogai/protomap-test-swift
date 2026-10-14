import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default care protocol proposal is in its life cycle.
    enum DefaultCareProtocolProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default care protocol proposal as the care protocol team keeps it.
    final class DefaultCareProtocolProposal {
        var code: String
        var title: String
        var retries: Int
        var refills: Int
        var copay: Double
        var region: String
        var attributes: [String: String]
        var status: DefaultCareProtocolProposalStatus

        init(code: String, title: String, retries: Int, refills: Int, copay: Double, region: String, attributes: [String: String], status: DefaultCareProtocolProposalStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.refills = refills
            self.copay = copay
            self.region = region
            self.attributes = attributes
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

        func canMoveTo(_ next: DefaultCareProtocolProposalStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultCareProtocolProposalStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultCareProtocolProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCareProtocolProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedVolume() -> Double {
            return (Double(retries) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareProtocolProposal {
            return DefaultCareProtocolProposal(
                code: code,
                title: title,
                retries: retries,
                refills: refills,
                copay: copay,
                region: region,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default care protocol proposal in status proposed.
    static func newDefaultCareProtocolProposal(_ code: String, title: String) -> DefaultCareProtocolProposal {
        return DefaultCareProtocolProposal(
            code: code,
            title: title,
            retries: 0,
            refills: 0,
            copay: 0.0,
            region: "",
            attributes: [:],
            status: DefaultCareProtocolProposalStatus.proposed
        )
    }
}
