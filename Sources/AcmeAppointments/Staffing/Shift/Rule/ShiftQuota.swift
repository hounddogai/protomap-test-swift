import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift quota is in its life cycle.
    enum ShiftQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A shift quota. Its code is unique within a tenant.
    final class ShiftQuota {
        var code: String
        var name: String
        var bed: String
        var diagnosisCode: String
        var active: Bool
        var acuity: Int
        var status: ShiftQuotaStatus

        init(code: String, name: String, bed: String, diagnosisCode: String, active: Bool, acuity: Int, status: ShiftQuotaStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.diagnosisCode = diagnosisCode
            self.active = active
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftQuotaStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ShiftQuotaStatus.published || next == ShiftQuotaStatus.retired
            case .published:
                return next == ShiftQuotaStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> ShiftQuota {
            return ShiftQuota(
                code: code,
                name: name,
                bed: bed,
                diagnosisCode: diagnosisCode,
                active: active,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a shift quota in status created.
    static func newShiftQuota(_ code: String, name: String) -> ShiftQuota {
        return ShiftQuota(
            code: code,
            name: name,
            bed: "",
            diagnosisCode: "",
            active: false,
            acuity: 0,
            status: ShiftQuotaStatus.created
        )
    }
}
