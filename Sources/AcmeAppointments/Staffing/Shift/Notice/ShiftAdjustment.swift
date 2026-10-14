import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift adjustment is in its life cycle.
    enum ShiftAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A shift adjustment as the shift team keeps it.
    final class ShiftAdjustment {
        var code: String
        var label: String
        var payer: String
        var unit: String
        var ward: String
        var diagnosisCode: String
        var locale: String
        var amount: Double
        var margin: Double
        var summary: String
        var expiresAt: Int
        var status: ShiftAdjustmentStatus

        init(code: String, label: String, payer: String, unit: String, ward: String, diagnosisCode: String, locale: String, amount: Double, margin: Double, summary: String, expiresAt: Int, status: ShiftAdjustmentStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.unit = unit
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.locale = locale
            self.amount = amount
            self.margin = margin
            self.summary = summary
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ShiftAdjustmentStatus.reopened
            case .reopened:
                return next == ShiftAdjustmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("shift adjustment") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(expiresAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ShiftAdjustment {
            return ShiftAdjustment(
                code: code,
                label: label,
                payer: payer,
                unit: unit,
                ward: ward,
                diagnosisCode: diagnosisCode,
                locale: locale,
                amount: amount,
                margin: margin,
                summary: summary,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a shift adjustment in status open.
    static func newShiftAdjustment(_ code: String, label: String) -> ShiftAdjustment {
        return ShiftAdjustment(
            code: code,
            label: label,
            payer: "",
            unit: "",
            ward: "",
            diagnosisCode: "",
            locale: "",
            amount: 0.0,
            margin: 0.0,
            summary: "",
            expiresAt: 0,
            status: ShiftAdjustmentStatus.`open`
        )
    }
}
