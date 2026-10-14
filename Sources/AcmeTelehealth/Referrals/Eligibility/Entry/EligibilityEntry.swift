import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility entry is in its life cycle.
    enum EligibilityEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a eligibility entry and its current status.
    final class EligibilityEntry {
        var code: String
        var name: String
        var sequence: Int
        var maximum: Double
        var label: String
        var batchSize: Int
        var status: EligibilityEntryStatus

        init(code: String, name: String, sequence: Int, maximum: Double, label: String, batchSize: Int, status: EligibilityEntryStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.maximum = maximum
            self.label = label
            self.batchSize = batchSize
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

        func canMoveTo(_ next: EligibilityEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == EligibilityEntryStatus.closed
            case .pending:
                return next == EligibilityEntryStatus.closed
            case .active:
                return next == EligibilityEntryStatus.suspended
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

        func moveTo(_ next: EligibilityEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return (Double(batchSize) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityEntry {
            return EligibilityEntry(
                code: code,
                name: name,
                sequence: sequence,
                maximum: maximum,
                label: label,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a eligibility entry in status draft.
    static func newEligibilityEntry(_ code: String, name: String) -> EligibilityEntry {
        return EligibilityEntry(
            code: code,
            name: name,
            sequence: 0,
            maximum: 0.0,
            label: "",
            batchSize: 0,
            status: EligibilityEntryStatus.draft
        )
    }
}
