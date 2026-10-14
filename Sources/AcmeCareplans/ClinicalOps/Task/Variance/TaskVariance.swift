import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task variance is in its life cycle.
    enum TaskVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One task variance, with what the planners need to act on it.
    final class TaskVariance {
        var code: String
        var title: String
        var pinned: Bool
        var encounterID: String
        var bed: String
        var allergy: String
        var quantity: Int
        var status: TaskVarianceStatus

        init(code: String, title: String, pinned: Bool, encounterID: String, bed: String, allergy: String, quantity: Int, status: TaskVarianceStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.encounterID = encounterID
            self.bed = bed
            self.allergy = allergy
            self.quantity = quantity
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

        func canMoveTo(_ next: TaskVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == TaskVarianceStatus.revoked || next == TaskVarianceStatus.expired
            case .revoked:
                return next == TaskVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("task variance") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> TaskVariance {
            return TaskVariance(
                code: code,
                title: title,
                pinned: pinned,
                encounterID: encounterID,
                bed: bed,
                allergy: allergy,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a task variance in status requested.
    static func newTaskVariance(_ code: String, title: String) -> TaskVariance {
        return TaskVariance(
            code: code,
            title: title,
            pinned: false,
            encounterID: "",
            bed: "",
            allergy: "",
            quantity: 0,
            status: TaskVarianceStatus.requested
        )
    }
}
