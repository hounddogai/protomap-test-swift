import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched goal template is in its life cycle.
    enum BatchedGoalTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched goal template as the goal team keeps it.
    final class BatchedGoalTemplate {
        var code: String
        var name: String
        var dosageMg: Double
        var specialty: String
        var copay: Double
        var acuity: Int
        var graceDays: Int
        var bed: String
        var status: BatchedGoalTemplateStatus

        init(code: String, name: String, dosageMg: Double, specialty: String, copay: Double, acuity: Int, graceDays: Int, bed: String, status: BatchedGoalTemplateStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.specialty = specialty
            self.copay = copay
            self.acuity = acuity
            self.graceDays = graceDays
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedGoalTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedGoalTemplateStatus.rejected
            case .approved:
                return next == BatchedGoalTemplateStatus.rejected || next == BatchedGoalTemplateStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: BatchedGoalTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched goal template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched goal template") \(code)"
        }

        func weightedExposure() -> Double {
            return ((copay - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedGoalTemplate {
            return BatchedGoalTemplate(
                code: code,
                name: name,
                dosageMg: dosageMg,
                specialty: specialty,
                copay: copay,
                acuity: acuity,
                graceDays: graceDays,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched goal template in status proposed.
    static func newBatchedGoalTemplate(_ code: String, name: String) -> BatchedGoalTemplate {
        return BatchedGoalTemplate(
            code: code,
            name: name,
            dosageMg: 0.0,
            specialty: "",
            copay: 0.0,
            acuity: 0,
            graceDays: 0,
            bed: "",
            status: BatchedGoalTemplateStatus.proposed
        )
    }
}
