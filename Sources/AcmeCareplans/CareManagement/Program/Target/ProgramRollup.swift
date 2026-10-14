import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program rollup is in its life cycle.
    enum ProgramRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A program rollup as the program team keeps it.
    final class ProgramRollup {
        var code: String
        var label: String
        var bed: String
        var retries: Int
        var ratio: Double
        var acuity: Int
        var archived: Bool
        var category: String
        var status: ProgramRollupStatus

        init(code: String, label: String, bed: String, retries: Int, ratio: Double, acuity: Int, archived: Bool, category: String, status: ProgramRollupStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.retries = retries
            self.ratio = ratio
            self.acuity = acuity
            self.archived = archived
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

        func canMoveTo(_ next: ProgramRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProgramRollupStatus.active || next == ProgramRollupStatus.suspended
            case .pending:
                return next == ProgramRollupStatus.suspended || next == ProgramRollupStatus.closed
            case .active:
                return next == ProgramRollupStatus.closed
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

        func moveTo(_ next: ProgramRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("program rollup") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(acuity) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ProgramRollup {
            return ProgramRollup(
                code: code,
                label: label,
                bed: bed,
                retries: retries,
                ratio: ratio,
                acuity: acuity,
                archived: archived,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a program rollup in status draft.
    static func newProgramRollup(_ code: String, label: String) -> ProgramRollup {
        return ProgramRollup(
            code: code,
            label: label,
            bed: "",
            retries: 0,
            ratio: 0.0,
            acuity: 0,
            archived: false,
            category: "",
            status: ProgramRollupStatus.draft
        )
    }
}
