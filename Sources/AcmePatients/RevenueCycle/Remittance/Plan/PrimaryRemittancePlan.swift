import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary remittance plan is in its life cycle.
    enum PrimaryRemittancePlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One primary remittance plan, with what the planners need to act on it.
    final class PrimaryRemittancePlan {
        var code: String
        var name: String
        var clinicianID: String
        var specialty: String
        var capacity: Int
        var reviewer: String
        var dosageMg: Double
        var status: PrimaryRemittancePlanStatus

        init(code: String, name: String, clinicianID: String, specialty: String, capacity: Int, reviewer: String, dosageMg: Double, status: PrimaryRemittancePlanStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.capacity = capacity
            self.reviewer = reviewer
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

        func canMoveTo(_ next: PrimaryRemittancePlanStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimaryRemittancePlanStatus.cancelled
            case .scheduled:
                return next == PrimaryRemittancePlanStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PrimaryRemittancePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary remittance plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary remittance plan") \(code)"
        }

        func netValue() -> Double {
            return ((dosageMg - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRemittancePlan {
            return PrimaryRemittancePlan(
                code: code,
                name: name,
                clinicianID: clinicianID,
                specialty: specialty,
                capacity: capacity,
                reviewer: reviewer,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary remittance plan in status planned.
    static func newPrimaryRemittancePlan(_ code: String, name: String) -> PrimaryRemittancePlan {
        return PrimaryRemittancePlan(
            code: code,
            name: name,
            clinicianID: "",
            specialty: "",
            capacity: 0,
            reviewer: "",
            dosageMg: 0.0,
            status: PrimaryRemittancePlanStatus.planned
        )
    }
}
