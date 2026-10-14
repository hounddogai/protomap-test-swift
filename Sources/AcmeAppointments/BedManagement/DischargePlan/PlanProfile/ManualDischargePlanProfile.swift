import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual discharge plan profile is in its life cycle.
    enum ManualDischargePlanProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual discharge plan profile as the discharge plan team keeps it.
    final class ManualDischargePlanProfile {
        var code: String
        var title: String
        var ceiling: Double
        var procedureCode: String
        var source: String
        var capacity: Int
        var notes: String
        var status: ManualDischargePlanProfileStatus

        init(code: String, title: String, ceiling: Double, procedureCode: String, source: String, capacity: Int, notes: String, status: ManualDischargePlanProfileStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.procedureCode = procedureCode
            self.source = source
            self.capacity = capacity
            self.notes = notes
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

        func canMoveTo(_ next: ManualDischargePlanProfileStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ManualDischargePlanProfileStatus.completed || next == ManualDischargePlanProfileStatus.cancelled
            case .completed:
                return next == ManualDischargePlanProfileStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualDischargePlanProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual discharge plan profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ManualDischargePlanProfile {
            return ManualDischargePlanProfile(
                code: code,
                title: title,
                ceiling: ceiling,
                procedureCode: procedureCode,
                source: source,
                capacity: capacity,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a manual discharge plan profile in status planned.
    static func newManualDischargePlanProfile(_ code: String, title: String) -> ManualDischargePlanProfile {
        return ManualDischargePlanProfile(
            code: code,
            title: title,
            ceiling: 0.0,
            procedureCode: "",
            source: "",
            capacity: 0,
            notes: "",
            status: ManualDischargePlanProfileStatus.planned
        )
    }
}
