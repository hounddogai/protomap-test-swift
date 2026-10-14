import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global task override is in its life cycle.
    enum GlobalTaskOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a global task override and its current status.
    final class GlobalTaskOverride {
        var code: String
        var title: String
        var dosageMg: Double
        var capacity: Int
        var name: String
        var pinned: Bool
        var archived: Bool
        var specialty: String
        var attempts: Int
        var phone: String
        var status: GlobalTaskOverrideStatus

        init(code: String, title: String, dosageMg: Double, capacity: Int, name: String, pinned: Bool, archived: Bool, specialty: String, attempts: Int, phone: String, status: GlobalTaskOverrideStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.name = name
            self.pinned = pinned
            self.archived = archived
            self.specialty = specialty
            self.attempts = attempts
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalTaskOverrideStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalTaskOverrideStatus.draining || next == GlobalTaskOverrideStatus.stopped
            case .warming:
                return next == GlobalTaskOverrideStatus.draining || next == GlobalTaskOverrideStatus.stopped
            case .ready:
                return next == GlobalTaskOverrideStatus.draining || next == GlobalTaskOverrideStatus.stopped
            case .draining:
                return next == GlobalTaskOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalTaskOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global task override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return ((Double(attempts) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalTaskOverride {
            return GlobalTaskOverride(
                code: code,
                title: title,
                dosageMg: dosageMg,
                capacity: capacity,
                name: name,
                pinned: pinned,
                archived: archived,
                specialty: specialty,
                attempts: attempts,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global task override in status idle.
    static func newGlobalTaskOverride(_ code: String, title: String) -> GlobalTaskOverride {
        return GlobalTaskOverride(
            code: code,
            title: title,
            dosageMg: 0.0,
            capacity: 0,
            name: "",
            pinned: false,
            archived: false,
            specialty: "",
            attempts: 0,
            phone: "",
            status: GlobalTaskOverrideStatus.idle
        )
    }
}
