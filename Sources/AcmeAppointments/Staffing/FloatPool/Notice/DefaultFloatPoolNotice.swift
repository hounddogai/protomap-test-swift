import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default float pool notice is in its life cycle.
    enum DefaultFloatPoolNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default float pool notice as the float pool team keeps it.
    final class DefaultFloatPoolNotice {
        var code: String
        var label: String
        var ratio: Double
        var graceDays: Int
        var summary: String
        var floorValue: Double
        var rate: Double
        var threshold: Double
        var startsAt: Int
        var status: DefaultFloatPoolNoticeStatus

        init(code: String, label: String, ratio: Double, graceDays: Int, summary: String, floorValue: Double, rate: Double, threshold: Double, startsAt: Int, status: DefaultFloatPoolNoticeStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.graceDays = graceDays
            self.summary = summary
            self.floorValue = floorValue
            self.rate = rate
            self.threshold = threshold
            self.startsAt = startsAt
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

        func canMoveTo(_ next: DefaultFloatPoolNoticeStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultFloatPoolNoticeStatus.running || next == DefaultFloatPoolNoticeStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultFloatPoolNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default float pool notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return (threshold * floorValue * 100).rounded() / 100
        }

        func copyValue() -> DefaultFloatPoolNotice {
            return DefaultFloatPoolNotice(
                code: code,
                label: label,
                ratio: ratio,
                graceDays: graceDays,
                summary: summary,
                floorValue: floorValue,
                rate: rate,
                threshold: threshold,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default float pool notice in status new.
    static func newDefaultFloatPoolNotice(_ code: String, label: String) -> DefaultFloatPoolNotice {
        return DefaultFloatPoolNotice(
            code: code,
            label: label,
            ratio: 0.0,
            graceDays: 0,
            summary: "",
            floorValue: 0.0,
            rate: 0.0,
            threshold: 0.0,
            startsAt: 0,
            status: DefaultFloatPoolNoticeStatus.new
        )
    }
}
