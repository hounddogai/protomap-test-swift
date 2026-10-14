import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary closure proposal is in its life cycle.
    enum PrimaryClosureProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary closure proposal as the closure team keeps it.
    final class PrimaryClosureProposal {
        var code: String
        var label: String
        var country: String
        var ward: String
        var priority: Int
        var retries: Int
        var notes: String
        var discount: Double
        var amount: Double
        var timezone: String
        var expiresAt: Int
        var status: PrimaryClosureProposalStatus

        init(code: String, label: String, country: String, ward: String, priority: Int, retries: Int, notes: String, discount: Double, amount: Double, timezone: String, expiresAt: Int, status: PrimaryClosureProposalStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.ward = ward
            self.priority = priority
            self.retries = retries
            self.notes = notes
            self.discount = discount
            self.amount = amount
            self.timezone = timezone
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: PrimaryClosureProposalStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
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

        func moveTo(_ next: PrimaryClosureProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary closure proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return ((Double(priority) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryClosureProposal {
            return PrimaryClosureProposal(
                code: code,
                label: label,
                country: country,
                ward: ward,
                priority: priority,
                retries: retries,
                notes: notes,
                discount: discount,
                amount: amount,
                timezone: timezone,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary closure proposal in status created.
    static func newPrimaryClosureProposal(_ code: String, label: String) -> PrimaryClosureProposal {
        return PrimaryClosureProposal(
            code: code,
            label: label,
            country: "",
            ward: "",
            priority: 0,
            retries: 0,
            notes: "",
            discount: 0.0,
            amount: 0.0,
            timezone: "",
            expiresAt: 0,
            status: PrimaryClosureProposalStatus.created
        )
    }
}
