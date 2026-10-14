import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual overtime variance is in its life cycle.
    enum ManualOvertimeVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a manual overtime variance and its current status.
    final class ManualOvertimeVariance {
        var code: String
        var label: String
        var phone: String
        var limit: Int
        var amount: Double
        var active: Bool
        var acuity: Int
        var status: ManualOvertimeVarianceStatus

        init(code: String, label: String, phone: String, limit: Int, amount: Double, active: Bool, acuity: Int, status: ManualOvertimeVarianceStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.limit = limit
            self.amount = amount
            self.active = active
            self.acuity = acuity
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

        func canMoveTo(_ next: ManualOvertimeVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ManualOvertimeVarianceStatus.revoked || next == ManualOvertimeVarianceStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ManualOvertimeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual overtime variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual overtime variance") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(limit) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> ManualOvertimeVariance {
            return ManualOvertimeVariance(
                code: code,
                label: label,
                phone: phone,
                limit: limit,
                amount: amount,
                active: active,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual overtime variance in status requested.
    static func newManualOvertimeVariance(_ code: String, label: String) -> ManualOvertimeVariance {
        return ManualOvertimeVariance(
            code: code,
            label: label,
            phone: "",
            limit: 0,
            amount: 0.0,
            active: false,
            acuity: 0,
            status: ManualOvertimeVarianceStatus.requested
        )
    }
}
