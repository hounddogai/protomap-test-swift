import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered statement adjustment is in its life cycle.
    enum TieredStatementAdjustmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a tiered statement adjustment and its current status.
    final class TieredStatementAdjustment {
        var code: String
        var label: String
        var dosageMg: Double
        var visitMinutes: Int
        var maximum: Double
        var startsAt: Int
        var status: TieredStatementAdjustmentStatus

        init(code: String, label: String, dosageMg: Double, visitMinutes: Int, maximum: Double, startsAt: Int, status: TieredStatementAdjustmentStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.startsAt = startsAt
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

        func canMoveTo(_ next: TieredStatementAdjustmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredStatementAdjustmentStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredStatementAdjustmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredStatementAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered statement adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("tiered statement adjustment") \(code)"
        }

        func netValue() -> Double {
            return ((Double(startsAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredStatementAdjustment {
            return TieredStatementAdjustment(
                code: code,
                label: label,
                dosageMg: dosageMg,
                visitMinutes: visitMinutes,
                maximum: maximum,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered statement adjustment in status proposed.
    static func newTieredStatementAdjustment(_ code: String, label: String) -> TieredStatementAdjustment {
        return TieredStatementAdjustment(
            code: code,
            label: label,
            dosageMg: 0.0,
            visitMinutes: 0,
            maximum: 0.0,
            startsAt: 0,
            status: TieredStatementAdjustmentStatus.proposed
        )
    }
}
