import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient acuity plan rollup is in its life cycle.
    enum LenientAcuityPlanRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient acuity plan rollup and its current status.
    final class LenientAcuityPlanRollup {
        var code: String
        var label: String
        var windowDays: Int
        var startsAt: Int
        var title: String
        var durationMinutes: Int
        var status: LenientAcuityPlanRollupStatus

        init(code: String, label: String, windowDays: Int, startsAt: Int, title: String, durationMinutes: Int, status: LenientAcuityPlanRollupStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.title = title
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: LenientAcuityPlanRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LenientAcuityPlanRollupStatus.resolved || next == LenientAcuityPlanRollupStatus.archived
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

        func moveTo(_ next: LenientAcuityPlanRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient acuity plan rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(startsAt) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientAcuityPlanRollup {
            return LenientAcuityPlanRollup(
                code: code,
                label: label,
                windowDays: windowDays,
                startsAt: startsAt,
                title: title,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient acuity plan rollup in status open.
    static func newLenientAcuityPlanRollup(_ code: String, label: String) -> LenientAcuityPlanRollup {
        return LenientAcuityPlanRollup(
            code: code,
            label: label,
            windowDays: 0,
            startsAt: 0,
            title: "",
            durationMinutes: 0,
            status: LenientAcuityPlanRollupStatus.`open`
        )
    }
}
