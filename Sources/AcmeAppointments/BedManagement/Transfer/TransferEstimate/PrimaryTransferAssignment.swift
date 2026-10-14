import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary transfer assignment is in its life cycle.
    enum PrimaryTransferAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One primary transfer assignment, with what the planners need to act on it.
    final class PrimaryTransferAssignment {
        var code: String
        var name: String
        var priority: Int
        var specialty: String
        var limit: Int
        var category: String
        var batchSize: Int
        var contactEmail: String
        var sequence: Int
        var currency: String
        var status: PrimaryTransferAssignmentStatus

        init(code: String, name: String, priority: Int, specialty: String, limit: Int, category: String, batchSize: Int, contactEmail: String, sequence: Int, currency: String, status: PrimaryTransferAssignmentStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.specialty = specialty
            self.limit = limit
            self.category = category
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.sequence = sequence
            self.currency = currency
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

        func canMoveTo(_ next: PrimaryTransferAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryTransferAssignmentStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryTransferAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary transfer assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return ((Double(priority) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryTransferAssignment {
            return PrimaryTransferAssignment(
                code: code,
                name: name,
                priority: priority,
                specialty: specialty,
                limit: limit,
                category: category,
                batchSize: batchSize,
                contactEmail: contactEmail,
                sequence: sequence,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary transfer assignment in status open.
    static func newPrimaryTransferAssignment(_ code: String, name: String) -> PrimaryTransferAssignment {
        return PrimaryTransferAssignment(
            code: code,
            name: name,
            priority: 0,
            specialty: "",
            limit: 0,
            category: "",
            batchSize: 0,
            contactEmail: "",
            sequence: 0,
            currency: "",
            status: PrimaryTransferAssignmentStatus.`open`
        )
    }
}
