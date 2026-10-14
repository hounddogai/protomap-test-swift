import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive closure metric is in its life cycle.
    enum AdaptiveClosureMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive closure metric. Its code is unique within a tenant.
    final class AdaptiveClosureMetric {
        var code: String
        var title: String
        var copay: Double
        var externalRef: String
        var unit: String
        var floorValue: Double
        var status: AdaptiveClosureMetricStatus

        init(code: String, title: String, copay: Double, externalRef: String, unit: String, floorValue: Double, status: AdaptiveClosureMetricStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.externalRef = externalRef
            self.unit = unit
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveClosureMetricStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AdaptiveClosureMetricStatus.suspended || next == AdaptiveClosureMetricStatus.closed
            case .active:
                return next == AdaptiveClosureMetricStatus.suspended
            case .suspended:
                return next == AdaptiveClosureMetricStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveClosureMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive closure metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netTotal() -> Double {
            return (copay * floorValue * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveClosureMetric {
            return AdaptiveClosureMetric(
                code: code,
                title: title,
                copay: copay,
                externalRef: externalRef,
                unit: unit,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive closure metric in status draft.
    static func newAdaptiveClosureMetric(_ code: String, title: String) -> AdaptiveClosureMetric {
        return AdaptiveClosureMetric(
            code: code,
            title: title,
            copay: 0.0,
            externalRef: "",
            unit: "",
            floorValue: 0.0,
            status: AdaptiveClosureMetricStatus.draft
        )
    }
}
