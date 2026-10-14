import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled program profile is in its life cycle.
    enum ScheduledProgramProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled program profile. Its code is unique within a tenant.
    final class ScheduledProgramProfile {
        var code: String
        var title: String
        var specialty: String
        var patientRef: String
        var cost: Double
        var visible: Bool
        var amount: Double
        var limit: Int
        var status: ScheduledProgramProfileStatus

        init(code: String, title: String, specialty: String, patientRef: String, cost: Double, visible: Bool, amount: Double, limit: Int, status: ScheduledProgramProfileStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.patientRef = patientRef
            self.cost = cost
            self.visible = visible
            self.amount = amount
            self.limit = limit
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

        func canMoveTo(_ next: ScheduledProgramProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ScheduledProgramProfileStatus.closed
            case .suspended:
                return next == ScheduledProgramProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledProgramProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled program profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveTotal() -> Double {
            return (amount * cost * 100).rounded() / 100
        }

        func copyValue() -> ScheduledProgramProfile {
            return ScheduledProgramProfile(
                code: code,
                title: title,
                specialty: specialty,
                patientRef: patientRef,
                cost: cost,
                visible: visible,
                amount: amount,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled program profile in status draft.
    static func newScheduledProgramProfile(_ code: String, title: String) -> ScheduledProgramProfile {
        return ScheduledProgramProfile(
            code: code,
            title: title,
            specialty: "",
            patientRef: "",
            cost: 0.0,
            visible: false,
            amount: 0.0,
            limit: 0,
            status: ScheduledProgramProfileStatus.draft
        )
    }
}
