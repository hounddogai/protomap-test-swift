import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient float pool estimate is in its life cycle.
    enum LenientFloatPoolEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a lenient float pool estimate and its current status.
    final class LenientFloatPoolEstimate {
        var code: String
        var title: String
        var procedureCode: String
        var maximum: Double
        var threshold: Double
        var cost: Double
        var status: LenientFloatPoolEstimateStatus

        init(code: String, title: String, procedureCode: String, maximum: Double, threshold: Double, cost: Double, status: LenientFloatPoolEstimateStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.threshold = threshold
            self.cost = cost
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

        func canMoveTo(_ next: LenientFloatPoolEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientFloatPoolEstimateStatus.queued || next == LenientFloatPoolEstimateStatus.running
            case .queued:
                return next == LenientFloatPoolEstimateStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LenientFloatPoolEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient float pool estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((threshold + maximum) * 100).rounded() / 100
        }

        func copyValue() -> LenientFloatPoolEstimate {
            return LenientFloatPoolEstimate(
                code: code,
                title: title,
                procedureCode: procedureCode,
                maximum: maximum,
                threshold: threshold,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient float pool estimate in status new.
    static func newLenientFloatPoolEstimate(_ code: String, title: String) -> LenientFloatPoolEstimate {
        return LenientFloatPoolEstimate(
            code: code,
            title: title,
            procedureCode: "",
            maximum: 0.0,
            threshold: 0.0,
            cost: 0.0,
            status: LenientFloatPoolEstimateStatus.new
        )
    }
}
