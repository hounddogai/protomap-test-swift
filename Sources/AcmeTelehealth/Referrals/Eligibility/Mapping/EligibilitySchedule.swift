import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility schedule is in its life cycle.
    enum EligibilityScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A eligibility schedule. Its code is unique within a tenant.
    final class EligibilitySchedule {
        var code: String
        var label: String
        var bed: String
        var clinicianID: String
        var weight: Double
        var procedureCode: String
        var status: EligibilityScheduleStatus

        init(code: String, label: String, bed: String, clinicianID: String, weight: Double, procedureCode: String, status: EligibilityScheduleStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.clinicianID = clinicianID
            self.weight = weight
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityScheduleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == EligibilityScheduleStatus.draining || next == EligibilityScheduleStatus.stopped
            case .ready:
                return next == EligibilityScheduleStatus.draining || next == EligibilityScheduleStatus.stopped
            case .draining:
                return next == EligibilityScheduleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> EligibilitySchedule {
            return EligibilitySchedule(
                code: code,
                label: label,
                bed: bed,
                clinicianID: clinicianID,
                weight: weight,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility schedule in status idle.
    static func newEligibilitySchedule(_ code: String, label: String) -> EligibilitySchedule {
        return EligibilitySchedule(
            code: code,
            label: label,
            bed: "",
            clinicianID: "",
            weight: 0.0,
            procedureCode: "",
            status: EligibilityScheduleStatus.idle
        )
    }
}
