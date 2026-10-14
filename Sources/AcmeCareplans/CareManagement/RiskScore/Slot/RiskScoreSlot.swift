import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score slot is in its life cycle.
    enum RiskScoreSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a risk score slot and its current status.
    final class RiskScoreSlot {
        var code: String
        var title: String
        var copay: Double
        var minimum: Double
        var unit: String
        var margin: Double
        var status: RiskScoreSlotStatus

        init(code: String, title: String, copay: Double, minimum: Double, unit: String, margin: Double, status: RiskScoreSlotStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.minimum = minimum
            self.unit = unit
            self.margin = margin
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

        func canMoveTo(_ next: RiskScoreSlotStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RiskScoreSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedTotal() -> Double {
            return ((minimum + copay) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreSlot {
            return RiskScoreSlot(
                code: code,
                title: title,
                copay: copay,
                minimum: minimum,
                unit: unit,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a risk score slot in status requested.
    static func newRiskScoreSlot(_ code: String, title: String) -> RiskScoreSlot {
        return RiskScoreSlot(
            code: code,
            title: title,
            copay: 0.0,
            minimum: 0.0,
            unit: "",
            margin: 0.0,
            status: RiskScoreSlotStatus.requested
        )
    }
}
