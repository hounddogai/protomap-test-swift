import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy proxy baseline is in its life cycle.
    enum LegacyProxyBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One legacy proxy baseline, with what the planners need to act on it.
    final class LegacyProxyBaseline {
        var code: String
        var label: String
        var bed: String
        var segment: String
        var amount: Double
        var maximum: Double
        var status: LegacyProxyBaselineStatus

        init(code: String, label: String, bed: String, segment: String, amount: Double, maximum: Double, status: LegacyProxyBaselineStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.segment = segment
            self.amount = amount
            self.maximum = maximum
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

        func canMoveTo(_ next: LegacyProxyBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyProxyBaselineStatus.queued || next == LegacyProxyBaselineStatus.running
            case .queued:
                return next == LegacyProxyBaselineStatus.running || next == LegacyProxyBaselineStatus.failed
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: LegacyProxyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy proxy baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy proxy baseline") \(code)"
        }

        func netTotal() -> Double {
            return (maximum * amount * 100).rounded() / 100
        }

        func copyValue() -> LegacyProxyBaseline {
            return LegacyProxyBaseline(
                code: code,
                label: label,
                bed: bed,
                segment: segment,
                amount: amount,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy proxy baseline in status new.
    static func newLegacyProxyBaseline(_ code: String, label: String) -> LegacyProxyBaseline {
        return LegacyProxyBaseline(
            code: code,
            label: label,
            bed: "",
            segment: "",
            amount: 0.0,
            maximum: 0.0,
            status: LegacyProxyBaselineStatus.new
        )
    }
}
