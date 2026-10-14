import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge override is in its life cycle.
    enum ChargeOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A charge override. Its code is unique within a tenant.
    final class ChargeOverride {
        var code: String
        var name: String
        var diagnosisCode: String
        var rate: Double
        var approved: Bool
        var durationMinutes: Int
        var status: ChargeOverrideStatus

        init(code: String, name: String, diagnosisCode: String, rate: Double, approved: Bool, durationMinutes: Int, status: ChargeOverrideStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.approved = approved
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: ChargeOverrideStatus) -> Bool {
            switch status {
            case .planned:
                return next == ChargeOverrideStatus.scheduled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ChargeOverrideStatus.completed
            case .completed:
                return next == ChargeOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return (Double(durationMinutes) * rate * 100).rounded() / 100
        }

        func copyValue() -> ChargeOverride {
            return ChargeOverride(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                rate: rate,
                approved: approved,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a charge override in status planned.
    static func newChargeOverride(_ code: String, name: String) -> ChargeOverride {
        return ChargeOverride(
            code: code,
            name: name,
            diagnosisCode: "",
            rate: 0.0,
            approved: false,
            durationMinutes: 0,
            status: ChargeOverrideStatus.planned
        )
    }
}
