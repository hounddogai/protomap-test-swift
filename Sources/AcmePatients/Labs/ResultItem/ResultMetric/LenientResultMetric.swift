import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient result metric is in its life cycle.
    enum LenientResultMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One lenient result metric, with what the planners need to act on it.
    final class LenientResultMetric {
        var code: String
        var name: String
        var segment: String
        var batchSize: Int
        var margin: Double
        var status: LenientResultMetricStatus

        init(code: String, name: String, segment: String, batchSize: Int, margin: Double, status: LenientResultMetricStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.batchSize = batchSize
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientResultMetricStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LenientResultMetricStatus.archived
            case .resolved:
                return next == LenientResultMetricStatus.reopened || next == LenientResultMetricStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LenientResultMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient result metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient result metric") \(code)"
        }

        func projectedTotal() -> Double {
            return ((margin - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> LenientResultMetric {
            return LenientResultMetric(
                code: code,
                name: name,
                segment: segment,
                batchSize: batchSize,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient result metric in status open.
    static func newLenientResultMetric(_ code: String, name: String) -> LenientResultMetric {
        return LenientResultMetric(
            code: code,
            name: name,
            segment: "",
            batchSize: 0,
            margin: 0.0,
            status: LenientResultMetricStatus.`open`
        )
    }
}
