import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning entry is in its life cycle.
    enum CleaningEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One cleaning entry, with what the planners need to act on it.
    final class CleaningEntry {
        var code: String
        var title: String
        var checksum: String
        var budget: Double
        var category: String
        var cost: Double
        var floorValue: Double
        var visible: Bool
        var externalRef: String
        var status: CleaningEntryStatus

        init(code: String, title: String, checksum: String, budget: Double, category: String, cost: Double, floorValue: Double, visible: Bool, externalRef: String, status: CleaningEntryStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.budget = budget
            self.category = category
            self.cost = cost
            self.floorValue = floorValue
            self.visible = visible
            self.externalRef = externalRef
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

        func canMoveTo(_ next: CleaningEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CleaningEntryStatus.approved || next == CleaningEntryStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CleaningEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("cleaning entry") \(code)"
        }

        func projectedVolume() -> Double {
            return (budget * floorValue * 100).rounded() / 100
        }

        func copyValue() -> CleaningEntry {
            return CleaningEntry(
                code: code,
                title: title,
                checksum: checksum,
                budget: budget,
                category: category,
                cost: cost,
                floorValue: floorValue,
                visible: visible,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a cleaning entry in status proposed.
    static func newCleaningEntry(_ code: String, title: String) -> CleaningEntry {
        return CleaningEntry(
            code: code,
            title: title,
            checksum: "",
            budget: 0.0,
            category: "",
            cost: 0.0,
            floorValue: 0.0,
            visible: false,
            externalRef: "",
            status: CleaningEntryStatus.proposed
        )
    }
}
