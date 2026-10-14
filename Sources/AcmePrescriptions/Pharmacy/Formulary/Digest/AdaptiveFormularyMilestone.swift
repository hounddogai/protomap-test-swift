import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive formulary milestone is in its life cycle.
    enum AdaptiveFormularyMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive formulary milestone. Its code is unique within a tenant.
    final class AdaptiveFormularyMilestone {
        var code: String
        var title: String
        var segment: String
        var startsAt: Int
        var margin: Double
        var channel: String
        var timezone: String
        var status: AdaptiveFormularyMilestoneStatus

        init(code: String, title: String, segment: String, startsAt: Int, margin: Double, channel: String, timezone: String, status: AdaptiveFormularyMilestoneStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.startsAt = startsAt
            self.margin = margin
            self.channel = channel
            self.timezone = timezone
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

        func canMoveTo(_ next: AdaptiveFormularyMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveFormularyMilestoneStatus.resolved || next == AdaptiveFormularyMilestoneStatus.archived
            case .resolved:
                return next == AdaptiveFormularyMilestoneStatus.reopened || next == AdaptiveFormularyMilestoneStatus.archived
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

        func moveTo(_ next: AdaptiveFormularyMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive formulary milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive formulary milestone") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(startsAt) - margin) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFormularyMilestone {
            return AdaptiveFormularyMilestone(
                code: code,
                title: title,
                segment: segment,
                startsAt: startsAt,
                margin: margin,
                channel: channel,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive formulary milestone in status open.
    static func newAdaptiveFormularyMilestone(_ code: String, title: String) -> AdaptiveFormularyMilestone {
        return AdaptiveFormularyMilestone(
            code: code,
            title: title,
            segment: "",
            startsAt: 0,
            margin: 0.0,
            channel: "",
            timezone: "",
            status: AdaptiveFormularyMilestoneStatus.`open`
        )
    }
}
