import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict task entry is in its life cycle.
    enum StrictTaskEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One strict task entry, with what the planners need to act on it.
    final class StrictTaskEntry {
        var code: String
        var label: String
        var active: Bool
        var procedureCode: String
        var approved: Bool
        var copay: Double
        var ceiling: Double
        var status: StrictTaskEntryStatus

        init(code: String, label: String, active: Bool, procedureCode: String, approved: Bool, copay: Double, ceiling: Double, status: StrictTaskEntryStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.procedureCode = procedureCode
            self.approved = approved
            self.copay = copay
            self.ceiling = ceiling
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

        func canMoveTo(_ next: StrictTaskEntryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictTaskEntryStatus.resolved || next == StrictTaskEntryStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StrictTaskEntryStatus.reopened
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

        func moveTo(_ next: StrictTaskEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict task entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict task entry") \(code)"
        }

        func weightedTotal() -> Double {
            return (copay * ceiling * 100).rounded() / 100
        }

        func copyValue() -> StrictTaskEntry {
            return StrictTaskEntry(
                code: code,
                label: label,
                active: active,
                procedureCode: procedureCode,
                approved: approved,
                copay: copay,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict task entry in status open.
    static func newStrictTaskEntry(_ code: String, label: String) -> StrictTaskEntry {
        return StrictTaskEntry(
            code: code,
            label: label,
            active: false,
            procedureCode: "",
            approved: false,
            copay: 0.0,
            ceiling: 0.0,
            status: StrictTaskEntryStatus.`open`
        )
    }
}
