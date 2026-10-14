import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched handoff window is in its life cycle.
    enum BatchedHandoffWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched handoff window. Its code is unique within a tenant.
    final class BatchedHandoffWindow {
        var code: String
        var title: String
        var endsAt: Int
        var refills: Int
        var margin: Double
        var patientRef: String
        var clinicianID: String
        var approved: Bool
        var budget: Double
        var dosageMg: Double
        var status: BatchedHandoffWindowStatus

        init(code: String, title: String, endsAt: Int, refills: Int, margin: Double, patientRef: String, clinicianID: String, approved: Bool, budget: Double, dosageMg: Double, status: BatchedHandoffWindowStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.refills = refills
            self.margin = margin
            self.patientRef = patientRef
            self.clinicianID = clinicianID
            self.approved = approved
            self.budget = budget
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: BatchedHandoffWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedHandoffWindowStatus.cancelled
            case .inProgress:
                return next == BatchedHandoffWindowStatus.completed || next == BatchedHandoffWindowStatus.cancelled
            case .completed:
                return next == BatchedHandoffWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedHandoffWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched handoff window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return (dosageMg * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> BatchedHandoffWindow {
            return BatchedHandoffWindow(
                code: code,
                title: title,
                endsAt: endsAt,
                refills: refills,
                margin: margin,
                patientRef: patientRef,
                clinicianID: clinicianID,
                approved: approved,
                budget: budget,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched handoff window in status planned.
    static func newBatchedHandoffWindow(_ code: String, title: String) -> BatchedHandoffWindow {
        return BatchedHandoffWindow(
            code: code,
            title: title,
            endsAt: 0,
            refills: 0,
            margin: 0.0,
            patientRef: "",
            clinicianID: "",
            approved: false,
            budget: 0.0,
            dosageMg: 0.0,
            status: BatchedHandoffWindowStatus.planned
        )
    }
}
