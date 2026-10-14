import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient reference range metric is in its life cycle.
    enum LenientReferenceRangeMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient reference range metric as the reference range team keeps it.
    final class LenientReferenceRangeMetric {
        var code: String
        var title: String
        var discount: Double
        var rate: Double
        var approved: Bool
        var pinned: Bool
        var status: LenientReferenceRangeMetricStatus

        init(code: String, title: String, discount: Double, rate: Double, approved: Bool, pinned: Bool, status: LenientReferenceRangeMetricStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.rate = rate
            self.approved = approved
            self.pinned = pinned
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

        func canMoveTo(_ next: LenientReferenceRangeMetricStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientReferenceRangeMetricStatus.failed
            case .queued:
                return next == LenientReferenceRangeMetricStatus.running || next == LenientReferenceRangeMetricStatus.done
            case .running:
                return next == LenientReferenceRangeMetricStatus.done || next == LenientReferenceRangeMetricStatus.failed
            case .done:
                return next == LenientReferenceRangeMetricStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientReferenceRangeMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient reference range metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return ((discount + rate) * 100).rounded() / 100
        }

        func copyValue() -> LenientReferenceRangeMetric {
            return LenientReferenceRangeMetric(
                code: code,
                title: title,
                discount: discount,
                rate: rate,
                approved: approved,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient reference range metric in status new.
    static func newLenientReferenceRangeMetric(_ code: String, title: String) -> LenientReferenceRangeMetric {
        return LenientReferenceRangeMetric(
            code: code,
            title: title,
            discount: 0.0,
            rate: 0.0,
            approved: false,
            pinned: false,
            status: LenientReferenceRangeMetricStatus.new
        )
    }
}
