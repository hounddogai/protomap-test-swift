import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding window is in its life cycle.
    enum RoundingWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rounding window, with what the planners need to act on it.
    final class RoundingWindow {
        var code: String
        var label: String
        var threshold: Double
        var category: String
        var ceiling: Double
        var segment: String
        var payer: String
        var weight: Double
        var timezone: String
        var status: RoundingWindowStatus

        init(code: String, label: String, threshold: Double, category: String, ceiling: Double, segment: String, payer: String, weight: Double, timezone: String, status: RoundingWindowStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.category = category
            self.ceiling = ceiling
            self.segment = segment
            self.payer = payer
            self.weight = weight
            self.timezone = timezone
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

        func canMoveTo(_ next: RoundingWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RoundingWindowStatus.done || next == RoundingWindowStatus.failed
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

        func moveTo(_ next: RoundingWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rounding window") \(code)"
        }

        func adjustedVolume() -> Double {
            return (ceiling * weight * 100).rounded() / 100
        }

        func copyValue() -> RoundingWindow {
            return RoundingWindow(
                code: code,
                label: label,
                threshold: threshold,
                category: category,
                ceiling: ceiling,
                segment: segment,
                payer: payer,
                weight: weight,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rounding window in status new.
    static func newRoundingWindow(_ code: String, label: String) -> RoundingWindow {
        return RoundingWindow(
            code: code,
            label: label,
            threshold: 0.0,
            category: "",
            ceiling: 0.0,
            segment: "",
            payer: "",
            weight: 0.0,
            timezone: "",
            status: RoundingWindowStatus.new
        )
    }
}
