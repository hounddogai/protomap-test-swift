import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary discharge plan adjustment is in its life cycle.
    enum PrimaryDischargePlanAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary discharge plan adjustment. Its code is unique within a tenant.
    final class PrimaryDischargePlanAdjustment {
        var code: String
        var title: String
        var diagnosisCode: String
        var rate: Double
        var durationMinutes: Int
        var status: PrimaryDischargePlanAdjustmentStatus

        init(code: String, title: String, diagnosisCode: String, rate: Double, durationMinutes: Int, status: PrimaryDischargePlanAdjustmentStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: PrimaryDischargePlanAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryDischargePlanAdjustmentStatus.active || next == PrimaryDischargePlanAdjustmentStatus.closed
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
                case .suspended, .closed:
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

        func moveTo(_ next: PrimaryDischargePlanAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary discharge plan adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary discharge plan adjustment") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(durationMinutes) - rate) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDischargePlanAdjustment {
            return PrimaryDischargePlanAdjustment(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                rate: rate,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary discharge plan adjustment in status draft.
    static func newPrimaryDischargePlanAdjustment(_ code: String, title: String) -> PrimaryDischargePlanAdjustment {
        return PrimaryDischargePlanAdjustment(
            code: code,
            title: title,
            diagnosisCode: "",
            rate: 0.0,
            durationMinutes: 0,
            status: PrimaryDischargePlanAdjustmentStatus.draft
        )
    }
}
