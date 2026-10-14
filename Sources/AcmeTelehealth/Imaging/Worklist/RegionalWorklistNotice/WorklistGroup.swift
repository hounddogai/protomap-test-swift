import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist group is in its life cycle.
    enum WorklistGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A worklist group. Its code is unique within a tenant.
    final class WorklistGroup {
        var code: String
        var title: String
        var priority: Int
        var unit: String
        var specialty: String
        var ownerID: String
        var payer: String
        var status: WorklistGroupStatus

        init(code: String, title: String, priority: Int, unit: String, specialty: String, ownerID: String, payer: String, status: WorklistGroupStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.unit = unit
            self.specialty = specialty
            self.ownerID = ownerID
            self.payer = payer
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

        func canMoveTo(_ next: WorklistGroupStatus) -> Bool {
            switch status {
            case .created:
                return next == WorklistGroupStatus.retired
            case .validated:
                return next == WorklistGroupStatus.published || next == WorklistGroupStatus.retired
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

        func moveTo(_ next: WorklistGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> WorklistGroup {
            return WorklistGroup(
                code: code,
                title: title,
                priority: priority,
                unit: unit,
                specialty: specialty,
                ownerID: ownerID,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a worklist group in status created.
    static func newWorklistGroup(_ code: String, title: String) -> WorklistGroup {
        return WorklistGroup(
            code: code,
            title: title,
            priority: 0,
            unit: "",
            specialty: "",
            ownerID: "",
            payer: "",
            status: WorklistGroupStatus.created
        )
    }
}
