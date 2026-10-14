import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime adjustment is in its life cycle.
    enum OvertimeAdjustmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A overtime adjustment as the overtime team keeps it.
    final class OvertimeAdjustment {
        var code: String
        var label: String
        var startsAt: Int
        var clinicianID: String
        var discount: Double
        var region: String
        var durationMinutes: Int
        var procedureCode: String
        var status: OvertimeAdjustmentStatus

        init(code: String, label: String, startsAt: Int, clinicianID: String, discount: Double, region: String, durationMinutes: Int, procedureCode: String, status: OvertimeAdjustmentStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.clinicianID = clinicianID
            self.discount = discount
            self.region = region
            self.durationMinutes = durationMinutes
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: OvertimeAdjustmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OvertimeAdjustmentStatus.approved
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: OvertimeAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return (Double(durationMinutes) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeAdjustment {
            return OvertimeAdjustment(
                code: code,
                label: label,
                startsAt: startsAt,
                clinicianID: clinicianID,
                discount: discount,
                region: region,
                durationMinutes: durationMinutes,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a overtime adjustment in status proposed.
    static func newOvertimeAdjustment(_ code: String, label: String) -> OvertimeAdjustment {
        return OvertimeAdjustment(
            code: code,
            label: label,
            startsAt: 0,
            clinicianID: "",
            discount: 0.0,
            region: "",
            durationMinutes: 0,
            procedureCode: "",
            status: OvertimeAdjustmentStatus.proposed
        )
    }
}
