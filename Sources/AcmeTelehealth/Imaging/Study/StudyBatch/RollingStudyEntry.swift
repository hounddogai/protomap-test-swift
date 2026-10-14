import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling study entry is in its life cycle.
    enum RollingStudyEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling study entry as the study team keeps it.
    final class RollingStudyEntry {
        var code: String
        var name: String
        var phone: String
        var updatedAt: Int
        var encounterID: String
        var acuity: Int
        var ceiling: Double
        var budget: Double
        var contactEmail: String
        var status: RollingStudyEntryStatus

        init(code: String, name: String, phone: String, updatedAt: Int, encounterID: String, acuity: Int, ceiling: Double, budget: Double, contactEmail: String, status: RollingStudyEntryStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.acuity = acuity
            self.ceiling = ceiling
            self.budget = budget
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: RollingStudyEntryStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingStudyEntryStatus.completed || next == RollingStudyEntryStatus.cancelled
            case .scheduled:
                return next == RollingStudyEntryStatus.cancelled
            case .inProgress:
                return next == RollingStudyEntryStatus.completed || next == RollingStudyEntryStatus.cancelled
            case .completed:
                return next == RollingStudyEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingStudyEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling study entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((Double(updatedAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> RollingStudyEntry {
            return RollingStudyEntry(
                code: code,
                name: name,
                phone: phone,
                updatedAt: updatedAt,
                encounterID: encounterID,
                acuity: acuity,
                ceiling: ceiling,
                budget: budget,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling study entry in status planned.
    static func newRollingStudyEntry(_ code: String, name: String) -> RollingStudyEntry {
        return RollingStudyEntry(
            code: code,
            name: name,
            phone: "",
            updatedAt: 0,
            encounterID: "",
            acuity: 0,
            ceiling: 0.0,
            budget: 0.0,
            contactEmail: "",
            status: RollingStudyEntryStatus.planned
        )
    }
}
