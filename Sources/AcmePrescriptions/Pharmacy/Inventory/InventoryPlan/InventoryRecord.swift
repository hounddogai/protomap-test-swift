import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory record is in its life cycle.
    enum InventoryRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A inventory record as the inventory team keeps it.
    final class InventoryRecord {
        var code: String
        var title: String
        var revision: Int
        var ceiling: Double
        var visible: Bool
        var description: String
        var status: InventoryRecordStatus

        init(code: String, title: String, revision: Int, ceiling: Double, visible: Bool, description: String, status: InventoryRecordStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.ceiling = ceiling
            self.visible = visible
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryRecordStatus) -> Bool {
            switch status {
            case .new:
                return next == InventoryRecordStatus.running || next == InventoryRecordStatus.done
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: InventoryRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveVolume() -> Double {
            return ((Double(revision) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> InventoryRecord {
            return InventoryRecord(
                code: code,
                title: title,
                revision: revision,
                ceiling: ceiling,
                visible: visible,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a inventory record in status new.
    static func newInventoryRecord(_ code: String, title: String) -> InventoryRecord {
        return InventoryRecord(
            code: code,
            title: title,
            revision: 0,
            ceiling: 0.0,
            visible: false,
            description: "",
            status: InventoryRecordStatus.new
        )
    }
}
