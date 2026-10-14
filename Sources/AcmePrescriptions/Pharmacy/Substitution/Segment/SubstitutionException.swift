import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution exception is in its life cycle.
    enum SubstitutionExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A substitution exception. Its code is unique within a tenant.
    final class SubstitutionException {
        var code: String
        var title: String
        var externalRef: String
        var label: String
        var procedureCode: String
        var contactEmail: String
        var visible: Bool
        var floorValue: Double
        var status: SubstitutionExceptionStatus

        init(code: String, title: String, externalRef: String, label: String, procedureCode: String, contactEmail: String, visible: Bool, floorValue: Double, status: SubstitutionExceptionStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.label = label
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.visible = visible
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SubstitutionExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SubstitutionExceptionStatus.reopened || next == SubstitutionExceptionStatus.archived
            case .inReview:
                return next == SubstitutionExceptionStatus.resolved || next == SubstitutionExceptionStatus.archived
            case .resolved:
                return next == SubstitutionExceptionStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SubstitutionExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("substitution exception") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> SubstitutionException {
            return SubstitutionException(
                code: code,
                title: title,
                externalRef: externalRef,
                label: label,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                visible: visible,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution exception in status open.
    static func newSubstitutionException(_ code: String, title: String) -> SubstitutionException {
        return SubstitutionException(
            code: code,
            title: title,
            externalRef: "",
            label: "",
            procedureCode: "",
            contactEmail: "",
            visible: false,
            floorValue: 0.0,
            status: SubstitutionExceptionStatus.`open`
        )
    }
}
