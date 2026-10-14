import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual statement rollup is in its life cycle.
    enum ManualStatementRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual statement rollup. Its code is unique within a tenant.
    final class ManualStatementRollup {
        var code: String
        var title: String
        var createdAt: Int
        var amount: Double
        var label: String
        var specialty: String
        var archived: Bool
        var durationMinutes: Int
        var copay: Double
        var status: ManualStatementRollupStatus

        init(code: String, title: String, createdAt: Int, amount: Double, label: String, specialty: String, archived: Bool, durationMinutes: Int, copay: Double, status: ManualStatementRollupStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.amount = amount
            self.label = label
            self.specialty = specialty
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualStatementRollupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ManualStatementRollupStatus.inProgress
            case .inProgress:
                return next == ManualStatementRollupStatus.completed || next == ManualStatementRollupStatus.cancelled
            case .completed:
                return next == ManualStatementRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualStatementRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual statement rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("manual statement rollup") \(code)"
        }

        func weightedTotal() -> Double {
            return ((copay + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualStatementRollup {
            return ManualStatementRollup(
                code: code,
                title: title,
                createdAt: createdAt,
                amount: amount,
                label: label,
                specialty: specialty,
                archived: archived,
                durationMinutes: durationMinutes,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual statement rollup in status planned.
    static func newManualStatementRollup(_ code: String, title: String) -> ManualStatementRollup {
        return ManualStatementRollup(
            code: code,
            title: title,
            createdAt: 0,
            amount: 0.0,
            label: "",
            specialty: "",
            archived: false,
            durationMinutes: 0,
            copay: 0.0,
            status: ManualStatementRollupStatus.planned
        )
    }
}
