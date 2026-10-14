import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict reference range rollup is in its life cycle.
    enum StrictReferenceRangeRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One strict reference range rollup, with what the planners need to act on it.
    final class StrictReferenceRangeRollup {
        var code: String
        var name: String
        var expiresAt: Int
        var archived: Bool
        var phone: String
        var unit: String
        var budget: Double
        var status: StrictReferenceRangeRollupStatus

        init(code: String, name: String, expiresAt: Int, archived: Bool, phone: String, unit: String, budget: Double, status: StrictReferenceRangeRollupStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.archived = archived
            self.phone = phone
            self.unit = unit
            self.budget = budget
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

        func canMoveTo(_ next: StrictReferenceRangeRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictReferenceRangeRollupStatus.active || next == StrictReferenceRangeRollupStatus.suspended
            case .pending:
                return next == StrictReferenceRangeRollupStatus.active || next == StrictReferenceRangeRollupStatus.suspended
            case .active:
                return next == StrictReferenceRangeRollupStatus.suspended || next == StrictReferenceRangeRollupStatus.closed
            case .suspended:
                return next == StrictReferenceRangeRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictReferenceRangeRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict reference range rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict reference range rollup") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((budget + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictReferenceRangeRollup {
            return StrictReferenceRangeRollup(
                code: code,
                name: name,
                expiresAt: expiresAt,
                archived: archived,
                phone: phone,
                unit: unit,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict reference range rollup in status draft.
    static func newStrictReferenceRangeRollup(_ code: String, name: String) -> StrictReferenceRangeRollup {
        return StrictReferenceRangeRollup(
            code: code,
            name: name,
            expiresAt: 0,
            archived: false,
            phone: "",
            unit: "",
            budget: 0.0,
            status: StrictReferenceRangeRollupStatus.draft
        )
    }
}
