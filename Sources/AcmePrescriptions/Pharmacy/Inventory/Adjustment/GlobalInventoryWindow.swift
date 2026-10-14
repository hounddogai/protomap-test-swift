import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global inventory window is in its life cycle.
    enum GlobalInventoryWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a global inventory window and its current status.
    final class GlobalInventoryWindow {
        var code: String
        var label: String
        var clinicianID: String
        var active: Bool
        var batchSize: Int
        var capacity: Int
        var status: GlobalInventoryWindowStatus

        init(code: String, label: String, clinicianID: String, active: Bool, batchSize: Int, capacity: Int, status: GlobalInventoryWindowStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.active = active
            self.batchSize = batchSize
            self.capacity = capacity
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

        func canMoveTo(_ next: GlobalInventoryWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalInventoryWindowStatus.validated || next == GlobalInventoryWindowStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalInventoryWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global inventory window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedVolume() -> Double {
            return (Double(batchSize) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> GlobalInventoryWindow {
            return GlobalInventoryWindow(
                code: code,
                label: label,
                clinicianID: clinicianID,
                active: active,
                batchSize: batchSize,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global inventory window in status created.
    static func newGlobalInventoryWindow(_ code: String, label: String) -> GlobalInventoryWindow {
        return GlobalInventoryWindow(
            code: code,
            label: label,
            clinicianID: "",
            active: false,
            batchSize: 0,
            capacity: 0,
            status: GlobalInventoryWindowStatus.created
        )
    }
}
