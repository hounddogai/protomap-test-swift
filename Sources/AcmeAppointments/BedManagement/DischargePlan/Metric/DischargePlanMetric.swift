import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan metric is in its life cycle.
    enum DischargePlanMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a discharge plan metric and its current status.
    final class DischargePlanMetric {
        var code: String
        var title: String
        var refills: Int
        var durationMinutes: Int
        var copay: Double
        var discount: Double
        var budget: Double
        var status: DischargePlanMetricStatus

        init(code: String, title: String, refills: Int, durationMinutes: Int, copay: Double, discount: Double, budget: Double, status: DischargePlanMetricStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.discount = discount
            self.budget = budget
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

        func canMoveTo(_ next: DischargePlanMetricStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DischargePlanMetricStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((copay + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanMetric {
            return DischargePlanMetric(
                code: code,
                title: title,
                refills: refills,
                durationMinutes: durationMinutes,
                copay: copay,
                discount: discount,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan metric in status created.
    static func newDischargePlanMetric(_ code: String, title: String) -> DischargePlanMetric {
        return DischargePlanMetric(
            code: code,
            title: title,
            refills: 0,
            durationMinutes: 0,
            copay: 0.0,
            discount: 0.0,
            budget: 0.0,
            status: DischargePlanMetricStatus.created
        )
    }
}
