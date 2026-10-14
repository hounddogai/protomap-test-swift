import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual shift adjustment is in its life cycle.
    enum ManualShiftAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a manual shift adjustment and its current status.
    final class ManualShiftAdjustment {
        var code: String
        var label: String
        var currency: String
        var visitMinutes: Int
        var limit: Int
        var cost: Double
        var phone: String
        var visible: Bool
        var segment: String
        var status: ManualShiftAdjustmentStatus

        init(code: String, label: String, currency: String, visitMinutes: Int, limit: Int, cost: Double, phone: String, visible: Bool, segment: String, status: ManualShiftAdjustmentStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.limit = limit
            self.cost = cost
            self.phone = phone
            self.visible = visible
            self.segment = segment
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

        func canMoveTo(_ next: ManualShiftAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ManualShiftAdjustmentStatus.revoked || next == ManualShiftAdjustmentStatus.expired
            case .revoked:
                return next == ManualShiftAdjustmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualShiftAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual shift adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return (cost * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> ManualShiftAdjustment {
            return ManualShiftAdjustment(
                code: code,
                label: label,
                currency: currency,
                visitMinutes: visitMinutes,
                limit: limit,
                cost: cost,
                phone: phone,
                visible: visible,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual shift adjustment in status requested.
    static func newManualShiftAdjustment(_ code: String, label: String) -> ManualShiftAdjustment {
        return ManualShiftAdjustment(
            code: code,
            label: label,
            currency: "",
            visitMinutes: 0,
            limit: 0,
            cost: 0.0,
            phone: "",
            visible: false,
            segment: "",
            status: ManualShiftAdjustmentStatus.requested
        )
    }
}
