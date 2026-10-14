import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled specimen tier is in its life cycle.
    enum ScheduledSpecimenTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One scheduled specimen tier, with what the planners need to act on it.
    final class ScheduledSpecimenTier {
        var code: String
        var title: String
        var ceiling: Double
        var minimum: Double
        var maximum: Double
        var retries: Int
        var copay: Double
        var description: String
        var status: ScheduledSpecimenTierStatus

        init(code: String, title: String, ceiling: Double, minimum: Double, maximum: Double, retries: Int, copay: Double, description: String, status: ScheduledSpecimenTierStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.minimum = minimum
            self.maximum = maximum
            self.retries = retries
            self.copay = copay
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledSpecimenTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ScheduledSpecimenTierStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ScheduledSpecimenTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled specimen tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled specimen tier") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((minimum - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledSpecimenTier {
            return ScheduledSpecimenTier(
                code: code,
                title: title,
                ceiling: ceiling,
                minimum: minimum,
                maximum: maximum,
                retries: retries,
                copay: copay,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled specimen tier in status planned.
    static func newScheduledSpecimenTier(_ code: String, title: String) -> ScheduledSpecimenTier {
        return ScheduledSpecimenTier(
            code: code,
            title: title,
            ceiling: 0.0,
            minimum: 0.0,
            maximum: 0.0,
            retries: 0,
            copay: 0.0,
            description: "",
            status: ScheduledSpecimenTierStatus.planned
        )
    }
}
