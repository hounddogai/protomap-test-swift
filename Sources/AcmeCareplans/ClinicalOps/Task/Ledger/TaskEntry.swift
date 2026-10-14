import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task entry is in its life cycle.
    enum TaskEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A task entry. Its code is unique within a tenant.
    final class TaskEntry {
        var code: String
        var title: String
        var dosageMg: Double
        var createdAt: Int
        var name: String
        var priority: Int
        var discount: Double
        var endsAt: Int
        var acuity: Int
        var status: TaskEntryStatus

        init(code: String, title: String, dosageMg: Double, createdAt: Int, name: String, priority: Int, discount: Double, endsAt: Int, acuity: Int, status: TaskEntryStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.name = name
            self.priority = priority
            self.discount = discount
            self.endsAt = endsAt
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == TaskEntryStatus.revoked
            case .granted:
                return next == TaskEntryStatus.revoked || next == TaskEntryStatus.expired
            case .revoked:
                return next == TaskEntryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(acuity) - discount) * 100).rounded() / 100
        }

        func copyValue() -> TaskEntry {
            return TaskEntry(
                code: code,
                title: title,
                dosageMg: dosageMg,
                createdAt: createdAt,
                name: name,
                priority: priority,
                discount: discount,
                endsAt: endsAt,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a task entry in status requested.
    static func newTaskEntry(_ code: String, title: String) -> TaskEntry {
        return TaskEntry(
            code: code,
            title: title,
            dosageMg: 0.0,
            createdAt: 0,
            name: "",
            priority: 0,
            discount: 0.0,
            endsAt: 0,
            acuity: 0,
            status: TaskEntryStatus.requested
        )
    }
}
