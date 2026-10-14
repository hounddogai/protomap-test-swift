import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure proposal is in its life cycle.
    enum DisclosureProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a disclosure proposal and its current status.
    final class DisclosureProposal {
        var code: String
        var label: String
        var endsAt: Int
        var contactEmail: String
        var version: Int
        var country: String
        var ownerID: String
        var ceiling: Double
        var amount: Double
        var batchSize: Int
        var status: DisclosureProposalStatus

        init(code: String, label: String, endsAt: Int, contactEmail: String, version: Int, country: String, ownerID: String, ceiling: Double, amount: Double, batchSize: Int, status: DisclosureProposalStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.contactEmail = contactEmail
            self.version = version
            self.country = country
            self.ownerID = ownerID
            self.ceiling = ceiling
            self.amount = amount
            self.batchSize = batchSize
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

        func canMoveTo(_ next: DisclosureProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DisclosureProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return ((Double(batchSize) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureProposal {
            return DisclosureProposal(
                code: code,
                label: label,
                endsAt: endsAt,
                contactEmail: contactEmail,
                version: version,
                country: country,
                ownerID: ownerID,
                ceiling: ceiling,
                amount: amount,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a disclosure proposal in status proposed.
    static func newDisclosureProposal(_ code: String, label: String) -> DisclosureProposal {
        return DisclosureProposal(
            code: code,
            label: label,
            endsAt: 0,
            contactEmail: "",
            version: 0,
            country: "",
            ownerID: "",
            ceiling: 0.0,
            amount: 0.0,
            batchSize: 0,
            status: DisclosureProposalStatus.proposed
        )
    }
}
