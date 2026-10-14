import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default transfer proposal is in its life cycle.
    enum DefaultTransferProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default transfer proposal, with what the planners need to act on it.
    final class DefaultTransferProposal {
        var code: String
        var label: String
        var cost: Double
        var revision: Int
        var contactEmail: String
        var source: String
        var currency: String
        var name: String
        var version: Int
        var locale: String
        var weight: Double
        var status: DefaultTransferProposalStatus

        init(code: String, label: String, cost: Double, revision: Int, contactEmail: String, source: String, currency: String, name: String, version: Int, locale: String, weight: Double, status: DefaultTransferProposalStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.revision = revision
            self.contactEmail = contactEmail
            self.source = source
            self.currency = currency
            self.name = name
            self.version = version
            self.locale = locale
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultTransferProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultTransferProposalStatus.warming || next == DefaultTransferProposalStatus.ready
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultTransferProposalStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultTransferProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default transfer proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return ((Double(revision) - cost) * 100).rounded() / 100
        }

        func copyValue() -> DefaultTransferProposal {
            return DefaultTransferProposal(
                code: code,
                label: label,
                cost: cost,
                revision: revision,
                contactEmail: contactEmail,
                source: source,
                currency: currency,
                name: name,
                version: version,
                locale: locale,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default transfer proposal in status idle.
    static func newDefaultTransferProposal(_ code: String, label: String) -> DefaultTransferProposal {
        return DefaultTransferProposal(
            code: code,
            label: label,
            cost: 0.0,
            revision: 0,
            contactEmail: "",
            source: "",
            currency: "",
            name: "",
            version: 0,
            locale: "",
            weight: 0.0,
            status: DefaultTransferProposalStatus.idle
        )
    }
}
