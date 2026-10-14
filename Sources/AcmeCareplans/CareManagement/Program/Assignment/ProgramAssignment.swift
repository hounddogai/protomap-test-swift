import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program assignment is in its life cycle.
    enum ProgramAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A program assignment. Its code is unique within a tenant.
    final class ProgramAssignment {
        var code: String
        var title: String
        var archived: Bool
        var quantity: Int
        var batchSize: Int
        var payer: String
        var country: String
        var sequence: Int
        var status: ProgramAssignmentStatus

        init(code: String, title: String, archived: Bool, quantity: Int, batchSize: Int, payer: String, country: String, sequence: Int, status: ProgramAssignmentStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.quantity = quantity
            self.batchSize = batchSize
            self.payer = payer
            self.country = country
            self.sequence = sequence
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

        func canMoveTo(_ next: ProgramAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProgramAssignmentStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ProgramAssignmentStatus.suspended || next == ProgramAssignmentStatus.closed
            case .suspended:
                return next == ProgramAssignmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return ((Double(quantity) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramAssignment {
            return ProgramAssignment(
                code: code,
                title: title,
                archived: archived,
                quantity: quantity,
                batchSize: batchSize,
                payer: payer,
                country: country,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a program assignment in status draft.
    static func newProgramAssignment(_ code: String, title: String) -> ProgramAssignment {
        return ProgramAssignment(
            code: code,
            title: title,
            archived: false,
            quantity: 0,
            batchSize: 0,
            payer: "",
            country: "",
            sequence: 0,
            status: ProgramAssignmentStatus.draft
        )
    }
}
