import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert schedule is in its life cycle.
    enum AlertScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One alert schedule, with what the planners need to act on it.
    final class AlertSchedule {
        var code: String
        var title: String
        var facility: String
        var updatedAt: Int
        var summary: String
        var patientRef: String
        var pinned: Bool
        var name: String
        var status: AlertScheduleStatus

        init(code: String, title: String, facility: String, updatedAt: Int, summary: String, patientRef: String, pinned: Bool, name: String, status: AlertScheduleStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.updatedAt = updatedAt
            self.summary = summary
            self.patientRef = patientRef
            self.pinned = pinned
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertScheduleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AlertScheduleStatus.published || next == AlertScheduleStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AlertScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("alert schedule") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> AlertSchedule {
            return AlertSchedule(
                code: code,
                title: title,
                facility: facility,
                updatedAt: updatedAt,
                summary: summary,
                patientRef: patientRef,
                pinned: pinned,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a alert schedule in status created.
    static func newAlertSchedule(_ code: String, title: String) -> AlertSchedule {
        return AlertSchedule(
            code: code,
            title: title,
            facility: "",
            updatedAt: 0,
            summary: "",
            patientRef: "",
            pinned: false,
            name: "",
            status: AlertScheduleStatus.created
        )
    }
}
