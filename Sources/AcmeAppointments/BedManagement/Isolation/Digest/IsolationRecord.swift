import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation record is in its life cycle.
    enum IsolationRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A isolation record as the isolation team keeps it.
    final class IsolationRecord {
        var code: String
        var label: String
        var weight: Double
        var segment: String
        var procedureCode: String
        var attempts: Int
        var allergy: String
        var category: String
        var minimum: Double
        var status: IsolationRecordStatus

        init(code: String, label: String, weight: Double, segment: String, procedureCode: String, attempts: Int, allergy: String, category: String, minimum: Double, status: IsolationRecordStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.segment = segment
            self.procedureCode = procedureCode
            self.attempts = attempts
            self.allergy = allergy
            self.category = category
            self.minimum = minimum
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

        func canMoveTo(_ next: IsolationRecordStatus) -> Bool {
            switch status {
            case .draft:
                return next == IsolationRecordStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == IsolationRecordStatus.suspended || next == IsolationRecordStatus.closed
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

        func moveTo(_ next: IsolationRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("isolation record") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(attempts) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> IsolationRecord {
            return IsolationRecord(
                code: code,
                label: label,
                weight: weight,
                segment: segment,
                procedureCode: procedureCode,
                attempts: attempts,
                allergy: allergy,
                category: category,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a isolation record in status draft.
    static func newIsolationRecord(_ code: String, label: String) -> IsolationRecord {
        return IsolationRecord(
            code: code,
            label: label,
            weight: 0.0,
            segment: "",
            procedureCode: "",
            attempts: 0,
            allergy: "",
            category: "",
            minimum: 0.0,
            status: IsolationRecordStatus.draft
        )
    }
}
