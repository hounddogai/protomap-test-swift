import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered care gap adjustment is in its life cycle.
    enum TieredCareGapAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One tiered care gap adjustment, with what the planners need to act on it.
    final class TieredCareGapAdjustment {
        var code: String
        var title: String
        var patientRef: String
        var clinicianID: String
        var ratio: Double
        var score: Double
        var dosageMg: Double
        var ceiling: Double
        var visitMinutes: Int
        var floorValue: Double
        var status: TieredCareGapAdjustmentStatus

        init(code: String, title: String, patientRef: String, clinicianID: String, ratio: Double, score: Double, dosageMg: Double, ceiling: Double, visitMinutes: Int, floorValue: Double, status: TieredCareGapAdjustmentStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.score = score
            self.dosageMg = dosageMg
            self.ceiling = ceiling
            self.visitMinutes = visitMinutes
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredCareGapAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TieredCareGapAdjustmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCareGapAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care gap adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((ratio + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareGapAdjustment {
            return TieredCareGapAdjustment(
                code: code,
                title: title,
                patientRef: patientRef,
                clinicianID: clinicianID,
                ratio: ratio,
                score: score,
                dosageMg: dosageMg,
                ceiling: ceiling,
                visitMinutes: visitMinutes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered care gap adjustment in status requested.
    static func newTieredCareGapAdjustment(_ code: String, title: String) -> TieredCareGapAdjustment {
        return TieredCareGapAdjustment(
            code: code,
            title: title,
            patientRef: "",
            clinicianID: "",
            ratio: 0.0,
            score: 0.0,
            dosageMg: 0.0,
            ceiling: 0.0,
            visitMinutes: 0,
            floorValue: 0.0,
            status: TieredCareGapAdjustmentStatus.requested
        )
    }
}
