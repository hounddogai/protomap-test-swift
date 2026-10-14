import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual dispense schedule is in its life cycle.
    enum ManualDispenseScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual dispense schedule. Its code is unique within a tenant.
    final class ManualDispenseSchedule {
        var code: String
        var title: String
        var windowDays: Int
        var phone: String
        var approved: Bool
        var allergy: String
        var ownerID: String
        var country: String
        var refills: Int
        var description: String
        var facility: String
        var status: ManualDispenseScheduleStatus

        init(code: String, title: String, windowDays: Int, phone: String, approved: Bool, allergy: String, ownerID: String, country: String, refills: Int, description: String, facility: String, status: ManualDispenseScheduleStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.phone = phone
            self.approved = approved
            self.allergy = allergy
            self.ownerID = ownerID
            self.country = country
            self.refills = refills
            self.description = description
            self.facility = facility
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

        func canMoveTo(_ next: ManualDispenseScheduleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ManualDispenseScheduleStatus.completed
            case .inProgress:
                return next == ManualDispenseScheduleStatus.cancelled
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

        func moveTo(_ next: ManualDispenseScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual dispense schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual dispense schedule") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(refills) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> ManualDispenseSchedule {
            return ManualDispenseSchedule(
                code: code,
                title: title,
                windowDays: windowDays,
                phone: phone,
                approved: approved,
                allergy: allergy,
                ownerID: ownerID,
                country: country,
                refills: refills,
                description: description,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual dispense schedule in status planned.
    static func newManualDispenseSchedule(_ code: String, title: String) -> ManualDispenseSchedule {
        return ManualDispenseSchedule(
            code: code,
            title: title,
            windowDays: 0,
            phone: "",
            approved: false,
            allergy: "",
            ownerID: "",
            country: "",
            refills: 0,
            description: "",
            facility: "",
            status: ManualDispenseScheduleStatus.planned
        )
    }
}
