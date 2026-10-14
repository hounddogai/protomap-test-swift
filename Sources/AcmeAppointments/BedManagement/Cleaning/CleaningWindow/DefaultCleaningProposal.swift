import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default cleaning proposal is in its life cycle.
    enum DefaultCleaningProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default cleaning proposal as the cleaning team keeps it.
    final class DefaultCleaningProposal {
        var code: String
        var name: String
        var segment: String
        var category: String
        var retries: Int
        var amount: Double
        var pinned: Bool
        var clinicianID: String
        var sequence: Int
        var region: String
        var status: DefaultCleaningProposalStatus

        init(code: String, name: String, segment: String, category: String, retries: Int, amount: Double, pinned: Bool, clinicianID: String, sequence: Int, region: String, status: DefaultCleaningProposalStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.category = category
            self.retries = retries
            self.amount = amount
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.region = region
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

        func canMoveTo(_ next: DefaultCleaningProposalStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
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

        func moveTo(_ next: DefaultCleaningProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default cleaning proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default cleaning proposal") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(retries) - amount) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCleaningProposal {
            return DefaultCleaningProposal(
                code: code,
                name: name,
                segment: segment,
                category: category,
                retries: retries,
                amount: amount,
                pinned: pinned,
                clinicianID: clinicianID,
                sequence: sequence,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default cleaning proposal in status requested.
    static func newDefaultCleaningProposal(_ code: String, name: String) -> DefaultCleaningProposal {
        return DefaultCleaningProposal(
            code: code,
            name: name,
            segment: "",
            category: "",
            retries: 0,
            amount: 0.0,
            pinned: false,
            clinicianID: "",
            sequence: 0,
            region: "",
            status: DefaultCleaningProposalStatus.requested
        )
    }
}
