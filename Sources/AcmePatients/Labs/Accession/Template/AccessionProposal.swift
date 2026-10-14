import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession proposal is in its life cycle.
    enum AccessionProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A accession proposal as the accession team keeps it.
    final class AccessionProposal {
        var code: String
        var name: String
        var allergy: String
        var phone: String
        var currency: String
        var summary: String
        var contactEmail: String
        var country: String
        var minimum: Double
        var cost: Double
        var maximum: Double
        var status: AccessionProposalStatus

        init(code: String, name: String, allergy: String, phone: String, currency: String, summary: String, contactEmail: String, country: String, minimum: Double, cost: Double, maximum: Double, status: AccessionProposalStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.phone = phone
            self.currency = currency
            self.summary = summary
            self.contactEmail = contactEmail
            self.country = country
            self.minimum = minimum
            self.cost = cost
            self.maximum = maximum
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

        func canMoveTo(_ next: AccessionProposalStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AccessionProposalStatus.done
            case .running:
                return next == AccessionProposalStatus.done || next == AccessionProposalStatus.failed
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

        func moveTo(_ next: AccessionProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return ((minimum + maximum) * 100).rounded() / 100
        }

        func copyValue() -> AccessionProposal {
            return AccessionProposal(
                code: code,
                name: name,
                allergy: allergy,
                phone: phone,
                currency: currency,
                summary: summary,
                contactEmail: contactEmail,
                country: country,
                minimum: minimum,
                cost: cost,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a accession proposal in status new.
    static func newAccessionProposal(_ code: String, name: String) -> AccessionProposal {
        return AccessionProposal(
            code: code,
            name: name,
            allergy: "",
            phone: "",
            currency: "",
            summary: "",
            contactEmail: "",
            country: "",
            minimum: 0.0,
            cost: 0.0,
            maximum: 0.0,
            status: AccessionProposalStatus.new
        )
    }
}
