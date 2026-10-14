import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional revocation agreement is in its life cycle.
    enum RegionalRevocationAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a regional revocation agreement and its current status.
    final class RegionalRevocationAgreement {
        var code: String
        var label: String
        var specialty: String
        var category: String
        var reviewer: String
        var maximum: Double
        var contactEmail: String
        var ownerID: String
        var allergy: String
        var status: RegionalRevocationAgreementStatus

        init(code: String, label: String, specialty: String, category: String, reviewer: String, maximum: Double, contactEmail: String, ownerID: String, allergy: String, status: RegionalRevocationAgreementStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.category = category
            self.reviewer = reviewer
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalRevocationAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalRevocationAgreementStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RegionalRevocationAgreementStatus.suspended || next == RegionalRevocationAgreementStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RegionalRevocationAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional revocation agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional revocation agreement") \(code)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> RegionalRevocationAgreement {
            return RegionalRevocationAgreement(
                code: code,
                label: label,
                specialty: specialty,
                category: category,
                reviewer: reviewer,
                maximum: maximum,
                contactEmail: contactEmail,
                ownerID: ownerID,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional revocation agreement in status draft.
    static func newRegionalRevocationAgreement(_ code: String, label: String) -> RegionalRevocationAgreement {
        return RegionalRevocationAgreement(
            code: code,
            label: label,
            specialty: "",
            category: "",
            reviewer: "",
            maximum: 0.0,
            contactEmail: "",
            ownerID: "",
            allergy: "",
            status: RegionalRevocationAgreementStatus.draft
        )
    }
}
