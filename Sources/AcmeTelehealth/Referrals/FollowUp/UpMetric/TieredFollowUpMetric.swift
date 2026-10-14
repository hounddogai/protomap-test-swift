import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered follow up metric is in its life cycle.
    enum TieredFollowUpMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered follow up metric as the follow up team keeps it.
    final class TieredFollowUpMetric {
        var code: String
        var label: String
        var durationMinutes: Int
        var cost: Double
        var unit: String
        var approved: Bool
        var budget: Double
        var ceiling: Double
        var sequence: Int
        var discount: Double
        var status: TieredFollowUpMetricStatus

        init(code: String, label: String, durationMinutes: Int, cost: Double, unit: String, approved: Bool, budget: Double, ceiling: Double, sequence: Int, discount: Double, status: TieredFollowUpMetricStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.unit = unit
            self.approved = approved
            self.budget = budget
            self.ceiling = ceiling
            self.sequence = sequence
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredFollowUpMetricStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TieredFollowUpMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredFollowUpMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered follow up metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((ceiling - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> TieredFollowUpMetric {
            return TieredFollowUpMetric(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                cost: cost,
                unit: unit,
                approved: approved,
                budget: budget,
                ceiling: ceiling,
                sequence: sequence,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered follow up metric in status idle.
    static func newTieredFollowUpMetric(_ code: String, label: String) -> TieredFollowUpMetric {
        return TieredFollowUpMetric(
            code: code,
            label: label,
            durationMinutes: 0,
            cost: 0.0,
            unit: "",
            approved: false,
            budget: 0.0,
            ceiling: 0.0,
            sequence: 0,
            discount: 0.0,
            status: TieredFollowUpMetricStatus.idle
        )
    }
}
