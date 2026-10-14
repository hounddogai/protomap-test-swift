import AcmePlatform
import Foundation

extension Labs {
    /// Where a result record is in its life cycle.
    enum ResultRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a result record and its current status.
    final class ResultRecord {
        var code: String
        var label: String
        var attributes: [String: String]
        var archived: Bool
        var sequence: Int
        var budget: Double
        var quantity: Int
        var status: ResultRecordStatus

        init(code: String, label: String, attributes: [String: String], archived: Bool, sequence: Int, budget: Double, quantity: Int, status: ResultRecordStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.archived = archived
            self.sequence = sequence
            self.budget = budget
            self.quantity = quantity
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

        func canMoveTo(_ next: ResultRecordStatus) -> Bool {
            switch status {
            case .draft:
                return next == ResultRecordStatus.suspended
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ResultRecordStatus.suspended || next == ResultRecordStatus.closed
            case .suspended:
                return next == ResultRecordStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((Double(sequence) - budget) * 100).rounded() / 100
        }

        func copyValue() -> ResultRecord {
            return ResultRecord(
                code: code,
                label: label,
                attributes: attributes,
                archived: archived,
                sequence: sequence,
                budget: budget,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a result record in status draft.
    static func newResultRecord(_ code: String, label: String) -> ResultRecord {
        return ResultRecord(
            code: code,
            label: label,
            attributes: [:],
            archived: false,
            sequence: 0,
            budget: 0.0,
            quantity: 0,
            status: ResultRecordStatus.draft
        )
    }
}
