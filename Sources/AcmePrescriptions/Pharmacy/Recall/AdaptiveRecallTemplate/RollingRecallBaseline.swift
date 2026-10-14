import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling recall baseline is in its life cycle.
    enum RollingRecallBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling recall baseline and its current status.
    final class RollingRecallBaseline {
        var code: String
        var label: String
        var margin: Double
        var endsAt: Int
        var visible: Bool
        var weight: Double
        var rate: Double
        var quantity: Int
        var budget: Double
        var name: String
        var status: RollingRecallBaselineStatus

        init(code: String, label: String, margin: Double, endsAt: Int, visible: Bool, weight: Double, rate: Double, quantity: Int, budget: Double, name: String, status: RollingRecallBaselineStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.endsAt = endsAt
            self.visible = visible
            self.weight = weight
            self.rate = rate
            self.quantity = quantity
            self.budget = budget
            self.name = name
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

        func canMoveTo(_ next: RollingRecallBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingRecallBaselineStatus.published || next == RollingRecallBaselineStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingRecallBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingRecallBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling recall baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return (Double(endsAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> RollingRecallBaseline {
            return RollingRecallBaseline(
                code: code,
                label: label,
                margin: margin,
                endsAt: endsAt,
                visible: visible,
                weight: weight,
                rate: rate,
                quantity: quantity,
                budget: budget,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling recall baseline in status created.
    static func newRollingRecallBaseline(_ code: String, label: String) -> RollingRecallBaseline {
        return RollingRecallBaseline(
            code: code,
            label: label,
            margin: 0.0,
            endsAt: 0,
            visible: false,
            weight: 0.0,
            rate: 0.0,
            quantity: 0,
            budget: 0.0,
            name: "",
            status: RollingRecallBaselineStatus.created
        )
    }
}
