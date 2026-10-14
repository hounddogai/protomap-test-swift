import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped task entry is in its life cycle.
    enum CappedTaskEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped task entry as the task team keeps it.
    final class CappedTaskEntry {
        var code: String
        var name: String
        var reviewer: String
        var title: String
        var ownerID: String
        var discount: Double
        var status: CappedTaskEntryStatus

        init(code: String, name: String, reviewer: String, title: String, ownerID: String, discount: Double, status: CappedTaskEntryStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.title = title
            self.ownerID = ownerID
            self.discount = discount
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

        func canMoveTo(_ next: CappedTaskEntryStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CappedTaskEntryStatus.rejected || next == CappedTaskEntryStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CappedTaskEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped task entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped task entry") \(code)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> CappedTaskEntry {
            return CappedTaskEntry(
                code: code,
                name: name,
                reviewer: reviewer,
                title: title,
                ownerID: ownerID,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped task entry in status proposed.
    static func newCappedTaskEntry(_ code: String, name: String) -> CappedTaskEntry {
        return CappedTaskEntry(
            code: code,
            name: name,
            reviewer: "",
            title: "",
            ownerID: "",
            discount: 0.0,
            status: CappedTaskEntryStatus.proposed
        )
    }
}
