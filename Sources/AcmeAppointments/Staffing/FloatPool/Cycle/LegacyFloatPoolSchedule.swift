import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy float pool schedule is in its life cycle.
    enum LegacyFloatPoolScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy float pool schedule. Its code is unique within a tenant.
    final class LegacyFloatPoolSchedule {
        var code: String
        var name: String
        var approved: Bool
        var ownerID: String
        var refills: Int
        var active: Bool
        var summary: String
        var contactEmail: String
        var title: String
        var ward: String
        var status: LegacyFloatPoolScheduleStatus

        init(code: String, name: String, approved: Bool, ownerID: String, refills: Int, active: Bool, summary: String, contactEmail: String, title: String, ward: String, status: LegacyFloatPoolScheduleStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.ownerID = ownerID
            self.refills = refills
            self.active = active
            self.summary = summary
            self.contactEmail = contactEmail
            self.title = title
            self.ward = ward
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

        func canMoveTo(_ next: LegacyFloatPoolScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyFloatPoolScheduleStatus.approved || next == LegacyFloatPoolScheduleStatus.rejected
            case .approved:
                return next == LegacyFloatPoolScheduleStatus.withdrawn
            case .rejected:
                return next == LegacyFloatPoolScheduleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyFloatPoolScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy float pool schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> LegacyFloatPoolSchedule {
            return LegacyFloatPoolSchedule(
                code: code,
                name: name,
                approved: approved,
                ownerID: ownerID,
                refills: refills,
                active: active,
                summary: summary,
                contactEmail: contactEmail,
                title: title,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy float pool schedule in status proposed.
    static func newLegacyFloatPoolSchedule(_ code: String, name: String) -> LegacyFloatPoolSchedule {
        return LegacyFloatPoolSchedule(
            code: code,
            name: name,
            approved: false,
            ownerID: "",
            refills: 0,
            active: false,
            summary: "",
            contactEmail: "",
            title: "",
            ward: "",
            status: LegacyFloatPoolScheduleStatus.proposed
        )
    }
}
