import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal acuity plan summary is in its life cycle.
    enum SeasonalAcuityPlanSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal acuity plan summary. Its code is unique within a tenant.
    final class SeasonalAcuityPlanSummary {
        var code: String
        var name: String
        var floorValue: Double
        var segment: String
        var amount: Double
        var status: SeasonalAcuityPlanSummaryStatus

        init(code: String, name: String, floorValue: Double, segment: String, amount: Double, status: SeasonalAcuityPlanSummaryStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.segment = segment
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalAcuityPlanSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalAcuityPlanSummaryStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalAcuityPlanSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalAcuityPlanSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal acuity plan summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedLoad() -> Double {
            return ((floorValue - amount) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAcuityPlanSummary {
            return SeasonalAcuityPlanSummary(
                code: code,
                name: name,
                floorValue: floorValue,
                segment: segment,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal acuity plan summary in status new.
    static func newSeasonalAcuityPlanSummary(_ code: String, name: String) -> SeasonalAcuityPlanSummary {
        return SeasonalAcuityPlanSummary(
            code: code,
            name: name,
            floorValue: 0.0,
            segment: "",
            amount: 0.0,
            status: SeasonalAcuityPlanSummaryStatus.new
        )
    }
}
