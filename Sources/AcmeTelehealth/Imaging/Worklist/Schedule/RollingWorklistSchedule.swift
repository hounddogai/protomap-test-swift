import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling worklist schedule is in its life cycle.
    enum RollingWorklistScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling worklist schedule as the worklist team keeps it.
    final class RollingWorklistSchedule {
        var code: String
        var label: String
        var title: String
        var approved: Bool
        var allergy: String
        var bed: String
        var phone: String
        var endsAt: Int
        var locale: String
        var durationMinutes: Int
        var status: RollingWorklistScheduleStatus

        init(code: String, label: String, title: String, approved: Bool, allergy: String, bed: String, phone: String, endsAt: Int, locale: String, durationMinutes: Int, status: RollingWorklistScheduleStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.approved = approved
            self.allergy = allergy
            self.bed = bed
            self.phone = phone
            self.endsAt = endsAt
            self.locale = locale
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: RollingWorklistScheduleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RollingWorklistScheduleStatus.retired
            case .published:
                return next == RollingWorklistScheduleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingWorklistScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling worklist schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("rolling worklist schedule") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RollingWorklistSchedule {
            return RollingWorklistSchedule(
                code: code,
                label: label,
                title: title,
                approved: approved,
                allergy: allergy,
                bed: bed,
                phone: phone,
                endsAt: endsAt,
                locale: locale,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling worklist schedule in status created.
    static func newRollingWorklistSchedule(_ code: String, label: String) -> RollingWorklistSchedule {
        return RollingWorklistSchedule(
            code: code,
            label: label,
            title: "",
            approved: false,
            allergy: "",
            bed: "",
            phone: "",
            endsAt: 0,
            locale: "",
            durationMinutes: 0,
            status: RollingWorklistScheduleStatus.created
        )
    }
}
