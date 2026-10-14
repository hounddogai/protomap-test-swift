import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered read variance is in its life cycle.
    enum TieredReadVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A tiered read variance as the read team keeps it.
    final class TieredReadVariance {
        var code: String
        var label: String
        var timezone: String
        var channel: String
        var priority: Int
        var procedureCode: String
        var minimum: Double
        var checksum: String
        var status: TieredReadVarianceStatus

        init(code: String, label: String, timezone: String, channel: String, priority: Int, procedureCode: String, minimum: Double, checksum: String, status: TieredReadVarianceStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.channel = channel
            self.priority = priority
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.checksum = checksum
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

        func canMoveTo(_ next: TieredReadVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredReadVarianceStatus.resolved || next == TieredReadVarianceStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredReadVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered read variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return (minimum * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> TieredReadVariance {
            return TieredReadVariance(
                code: code,
                label: label,
                timezone: timezone,
                channel: channel,
                priority: priority,
                procedureCode: procedureCode,
                minimum: minimum,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a tiered read variance in status open.
    static func newTieredReadVariance(_ code: String, label: String) -> TieredReadVariance {
        return TieredReadVariance(
            code: code,
            label: label,
            timezone: "",
            channel: "",
            priority: 0,
            procedureCode: "",
            minimum: 0.0,
            checksum: "",
            status: TieredReadVarianceStatus.`open`
        )
    }
}
