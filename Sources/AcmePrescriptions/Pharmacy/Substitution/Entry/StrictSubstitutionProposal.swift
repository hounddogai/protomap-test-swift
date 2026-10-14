import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict substitution proposal is in its life cycle.
    enum StrictSubstitutionProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict substitution proposal as the substitution team keeps it.
    final class StrictSubstitutionProposal {
        var code: String
        var name: String
        var country: String
        var segment: String
        var quantity: Int
        var facility: String
        var attempts: Int
        var notes: String
        var version: Int
        var status: StrictSubstitutionProposalStatus

        init(code: String, name: String, country: String, segment: String, quantity: Int, facility: String, attempts: Int, notes: String, version: Int, status: StrictSubstitutionProposalStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.segment = segment
            self.quantity = quantity
            self.facility = facility
            self.attempts = attempts
            self.notes = notes
            self.version = version
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

        func canMoveTo(_ next: StrictSubstitutionProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StrictSubstitutionProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSubstitutionProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict substitution proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("strict substitution proposal") \(code)"
        }

        func netExposure() -> Double {
            return (Double(version) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> StrictSubstitutionProposal {
            return StrictSubstitutionProposal(
                code: code,
                name: name,
                country: country,
                segment: segment,
                quantity: quantity,
                facility: facility,
                attempts: attempts,
                notes: notes,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a strict substitution proposal in status open.
    static func newStrictSubstitutionProposal(_ code: String, name: String) -> StrictSubstitutionProposal {
        return StrictSubstitutionProposal(
            code: code,
            name: name,
            country: "",
            segment: "",
            quantity: 0,
            facility: "",
            attempts: 0,
            notes: "",
            version: 0,
            status: StrictSubstitutionProposalStatus.`open`
        )
    }
}
