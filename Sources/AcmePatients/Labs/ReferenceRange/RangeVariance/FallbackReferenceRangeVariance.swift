import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback reference range variance is in its life cycle.
    enum FallbackReferenceRangeVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback reference range variance, with what the planners need to act on it.
    final class FallbackReferenceRangeVariance {
        var code: String
        var label: String
        var ceiling: Double
        var ratio: Double
        var capacity: Int
        var title: String
        var specialty: String
        var region: String
        var status: FallbackReferenceRangeVarianceStatus

        init(code: String, label: String, ceiling: Double, ratio: Double, capacity: Int, title: String, specialty: String, region: String, status: FallbackReferenceRangeVarianceStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.ratio = ratio
            self.capacity = capacity
            self.title = title
            self.specialty = specialty
            self.region = region
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

        func canMoveTo(_ next: FallbackReferenceRangeVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FallbackReferenceRangeVarianceStatus.done || next == FallbackReferenceRangeVarianceStatus.failed
            case .done:
                return next == FallbackReferenceRangeVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackReferenceRangeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback reference range variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedLoad() -> Double {
            return ((Double(capacity) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> FallbackReferenceRangeVariance {
            return FallbackReferenceRangeVariance(
                code: code,
                label: label,
                ceiling: ceiling,
                ratio: ratio,
                capacity: capacity,
                title: title,
                specialty: specialty,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback reference range variance in status new.
    static func newFallbackReferenceRangeVariance(_ code: String, label: String) -> FallbackReferenceRangeVariance {
        return FallbackReferenceRangeVariance(
            code: code,
            label: label,
            ceiling: 0.0,
            ratio: 0.0,
            capacity: 0,
            title: "",
            specialty: "",
            region: "",
            status: FallbackReferenceRangeVarianceStatus.new
        )
    }
}
