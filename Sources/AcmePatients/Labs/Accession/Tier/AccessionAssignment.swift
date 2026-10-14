import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession assignment is in its life cycle.
    enum AccessionAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One accession assignment, with what the planners need to act on it.
    final class AccessionAssignment {
        var code: String
        var label: String
        var retries: Int
        var contactEmail: String
        var threshold: Double
        var graceDays: Int
        var source: String
        var currency: String
        var patientRef: String
        var rate: Double
        var category: String
        var status: AccessionAssignmentStatus

        init(code: String, label: String, retries: Int, contactEmail: String, threshold: Double, graceDays: Int, source: String, currency: String, patientRef: String, rate: Double, category: String, status: AccessionAssignmentStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.contactEmail = contactEmail
            self.threshold = threshold
            self.graceDays = graceDays
            self.source = source
            self.currency = currency
            self.patientRef = patientRef
            self.rate = rate
            self.category = category
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

        func canMoveTo(_ next: AccessionAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AccessionAssignmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(retries) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> AccessionAssignment {
            return AccessionAssignment(
                code: code,
                label: label,
                retries: retries,
                contactEmail: contactEmail,
                threshold: threshold,
                graceDays: graceDays,
                source: source,
                currency: currency,
                patientRef: patientRef,
                rate: rate,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a accession assignment in status draft.
    static func newAccessionAssignment(_ code: String, label: String) -> AccessionAssignment {
        return AccessionAssignment(
            code: code,
            label: label,
            retries: 0,
            contactEmail: "",
            threshold: 0.0,
            graceDays: 0,
            source: "",
            currency: "",
            patientRef: "",
            rate: 0.0,
            category: "",
            status: AccessionAssignmentStatus.draft
        )
    }
}
