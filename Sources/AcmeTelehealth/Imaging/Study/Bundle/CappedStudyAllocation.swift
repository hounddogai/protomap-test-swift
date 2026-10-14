import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped study allocation is in its life cycle.
    enum CappedStudyAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped study allocation as the study team keeps it.
    final class CappedStudyAllocation {
        var code: String
        var label: String
        var country: String
        var contactEmail: String
        var externalRef: String
        var quantity: Int
        var status: CappedStudyAllocationStatus

        init(code: String, label: String, country: String, contactEmail: String, externalRef: String, quantity: Int, status: CappedStudyAllocationStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.contactEmail = contactEmail
            self.externalRef = externalRef
            self.quantity = quantity
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

        func canMoveTo(_ next: CappedStudyAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CappedStudyAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedStudyAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped study allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CappedStudyAllocation {
            return CappedStudyAllocation(
                code: code,
                label: label,
                country: country,
                contactEmail: contactEmail,
                externalRef: externalRef,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped study allocation in status proposed.
    static func newCappedStudyAllocation(_ code: String, label: String) -> CappedStudyAllocation {
        return CappedStudyAllocation(
            code: code,
            label: label,
            country: "",
            contactEmail: "",
            externalRef: "",
            quantity: 0,
            status: CappedStudyAllocationStatus.proposed
        )
    }
}
