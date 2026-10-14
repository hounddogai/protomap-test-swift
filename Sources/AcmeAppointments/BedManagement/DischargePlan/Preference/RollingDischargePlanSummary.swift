import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling discharge plan summary is in its life cycle.
    enum RollingDischargePlanSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling discharge plan summary. Its code is unique within a tenant.
    final class RollingDischargePlanSummary {
        var code: String
        var title: String
        var windowDays: Int
        var attempts: Int
        var score: Double
        var margin: Double
        var ratio: Double
        var reviewer: String
        var tags: [String]
        var status: RollingDischargePlanSummaryStatus

        init(code: String, title: String, windowDays: Int, attempts: Int, score: Double, margin: Double, ratio: Double, reviewer: String, tags: [String], status: RollingDischargePlanSummaryStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.attempts = attempts
            self.score = score
            self.margin = margin
            self.ratio = ratio
            self.reviewer = reviewer
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingDischargePlanSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingDischargePlanSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling discharge plan summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return (Double(attempts) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> RollingDischargePlanSummary {
            return RollingDischargePlanSummary(
                code: code,
                title: title,
                windowDays: windowDays,
                attempts: attempts,
                score: score,
                margin: margin,
                ratio: ratio,
                reviewer: reviewer,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling discharge plan summary in status proposed.
    static func newRollingDischargePlanSummary(_ code: String, title: String) -> RollingDischargePlanSummary {
        return RollingDischargePlanSummary(
            code: code,
            title: title,
            windowDays: 0,
            attempts: 0,
            score: 0.0,
            margin: 0.0,
            ratio: 0.0,
            reviewer: "",
            tags: [],
            status: RollingDischargePlanSummaryStatus.proposed
        )
    }
}
