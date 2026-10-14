import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global handoff schedule is in its life cycle.
    enum GlobalHandoffScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a global handoff schedule and its current status.
    final class GlobalHandoffSchedule {
        var code: String
        var name: String
        var ward: String
        var margin: Double
        var channel: String
        var status: GlobalHandoffScheduleStatus

        init(code: String, name: String, ward: String, margin: Double, channel: String, status: GlobalHandoffScheduleStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.margin = margin
            self.channel = channel
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

        func canMoveTo(_ next: GlobalHandoffScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GlobalHandoffScheduleStatus.reopened || next == GlobalHandoffScheduleStatus.archived
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

        func moveTo(_ next: GlobalHandoffScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global handoff schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> GlobalHandoffSchedule {
            return GlobalHandoffSchedule(
                code: code,
                name: name,
                ward: ward,
                margin: margin,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a global handoff schedule in status open.
    static func newGlobalHandoffSchedule(_ code: String, name: String) -> GlobalHandoffSchedule {
        return GlobalHandoffSchedule(
            code: code,
            name: name,
            ward: "",
            margin: 0.0,
            channel: "",
            status: GlobalHandoffScheduleStatus.`open`
        )
    }
}
