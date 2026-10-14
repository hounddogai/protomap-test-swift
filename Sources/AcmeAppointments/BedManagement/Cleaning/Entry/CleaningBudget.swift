import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning budget is in its life cycle.
    enum CleaningBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a cleaning budget and its current status.
    final class CleaningBudget {
        var code: String
        var name: String
        var durationMinutes: Int
        var visible: Bool
        var specialty: String
        var amount: Double
        var acuity: Int
        var summary: String
        var endsAt: Int
        var pinned: Bool
        var status: CleaningBudgetStatus

        init(code: String, name: String, durationMinutes: Int, visible: Bool, specialty: String, amount: Double, acuity: Int, summary: String, endsAt: Int, pinned: Bool, status: CleaningBudgetStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.visible = visible
            self.specialty = specialty
            self.amount = amount
            self.acuity = acuity
            self.summary = summary
            self.endsAt = endsAt
            self.pinned = pinned
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

        func canMoveTo(_ next: CleaningBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CleaningBudgetStatus.active || next == CleaningBudgetStatus.suspended
            case .active:
                return next == CleaningBudgetStatus.suspended
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

        func moveTo(_ next: CleaningBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedExposure() -> Double {
            return (Double(endsAt) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> CleaningBudget {
            return CleaningBudget(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                visible: visible,
                specialty: specialty,
                amount: amount,
                acuity: acuity,
                summary: summary,
                endsAt: endsAt,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a cleaning budget in status draft.
    static func newCleaningBudget(_ code: String, name: String) -> CleaningBudget {
        return CleaningBudget(
            code: code,
            name: name,
            durationMinutes: 0,
            visible: false,
            specialty: "",
            amount: 0.0,
            acuity: 0,
            summary: "",
            endsAt: 0,
            pinned: false,
            status: CleaningBudgetStatus.draft
        )
    }
}
