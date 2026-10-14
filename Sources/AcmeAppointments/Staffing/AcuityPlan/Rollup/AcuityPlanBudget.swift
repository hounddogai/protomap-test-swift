import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan budget is in its life cycle.
    enum AcuityPlanBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A acuity plan budget as the acuity plan team keeps it.
    final class AcuityPlanBudget {
        var code: String
        var name: String
        var patientRef: String
        var threshold: Double
        var phone: String
        var expiresAt: Int
        var status: AcuityPlanBudgetStatus

        init(code: String, name: String, patientRef: String, threshold: Double, phone: String, expiresAt: Int, status: AcuityPlanBudgetStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.threshold = threshold
            self.phone = phone
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: AcuityPlanBudgetStatus) -> Bool {
            switch status {
            case .draft:
                return next == AcuityPlanBudgetStatus.pending || next == AcuityPlanBudgetStatus.active
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AcuityPlanBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("acuity plan budget") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(expiresAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanBudget {
            return AcuityPlanBudget(
                code: code,
                name: name,
                patientRef: patientRef,
                threshold: threshold,
                phone: phone,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a acuity plan budget in status draft.
    static func newAcuityPlanBudget(_ code: String, name: String) -> AcuityPlanBudget {
        return AcuityPlanBudget(
            code: code,
            name: name,
            patientRef: "",
            threshold: 0.0,
            phone: "",
            expiresAt: 0,
            status: AcuityPlanBudgetStatus.draft
        )
    }
}
