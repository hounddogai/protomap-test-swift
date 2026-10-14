import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan summary is in its life cycle.
    enum DischargePlanSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One discharge plan summary, with what the planners need to act on it.
    final class DischargePlanSummary {
        var code: String
        var label: String
        var description: String
        var clinicianID: String
        var quantity: Int
        var checksum: String
        var country: String
        var contactEmail: String
        var status: DischargePlanSummaryStatus

        init(code: String, label: String, description: String, clinicianID: String, quantity: Int, checksum: String, country: String, contactEmail: String, status: DischargePlanSummaryStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.clinicianID = clinicianID
            self.quantity = quantity
            self.checksum = checksum
            self.country = country
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: DischargePlanSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DischargePlanSummaryStatus.withdrawn
            case .rejected:
                return next == DischargePlanSummaryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> DischargePlanSummary {
            return DischargePlanSummary(
                code: code,
                label: label,
                description: description,
                clinicianID: clinicianID,
                quantity: quantity,
                checksum: checksum,
                country: country,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a discharge plan summary in status proposed.
    static func newDischargePlanSummary(_ code: String, label: String) -> DischargePlanSummary {
        return DischargePlanSummary(
            code: code,
            label: label,
            description: "",
            clinicianID: "",
            quantity: 0,
            checksum: "",
            country: "",
            contactEmail: "",
            status: DischargePlanSummaryStatus.proposed
        )
    }
}
