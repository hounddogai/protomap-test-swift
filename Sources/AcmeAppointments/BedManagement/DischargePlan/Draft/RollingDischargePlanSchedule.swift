import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling discharge plan schedule is in its life cycle.
    enum RollingDischargePlanScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rolling discharge plan schedule, with what the planners need to act on it.
    final class RollingDischargePlanSchedule {
        var code: String
        var label: String
        var category: String
        var ceiling: Double
        var segment: String
        var unit: String
        var attributes: [String: String]
        var channel: String
        var maximum: Double
        var approved: Bool
        var status: RollingDischargePlanScheduleStatus

        init(code: String, label: String, category: String, ceiling: Double, segment: String, unit: String, attributes: [String: String], channel: String, maximum: Double, approved: Bool, status: RollingDischargePlanScheduleStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.ceiling = ceiling
            self.segment = segment
            self.unit = unit
            self.attributes = attributes
            self.channel = channel
            self.maximum = maximum
            self.approved = approved
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

        func canMoveTo(_ next: RollingDischargePlanScheduleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RollingDischargePlanScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingDischargePlanScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling discharge plan schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling discharge plan schedule") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedExposure() -> Double {
            return (ceiling * maximum * 100).rounded() / 100
        }

        func copyValue() -> RollingDischargePlanSchedule {
            return RollingDischargePlanSchedule(
                code: code,
                label: label,
                category: category,
                ceiling: ceiling,
                segment: segment,
                unit: unit,
                attributes: attributes,
                channel: channel,
                maximum: maximum,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling discharge plan schedule in status planned.
    static func newRollingDischargePlanSchedule(_ code: String, label: String) -> RollingDischargePlanSchedule {
        return RollingDischargePlanSchedule(
            code: code,
            label: label,
            category: "",
            ceiling: 0.0,
            segment: "",
            unit: "",
            attributes: [:],
            channel: "",
            maximum: 0.0,
            approved: false,
            status: RollingDischargePlanScheduleStatus.planned
        )
    }
}
