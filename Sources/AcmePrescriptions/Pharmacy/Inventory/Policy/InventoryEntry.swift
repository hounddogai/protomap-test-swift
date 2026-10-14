import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory entry is in its life cycle.
    enum InventoryEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One inventory entry, with what the planners need to act on it.
    final class InventoryEntry {
        var code: String
        var label: String
        var category: String
        var clinicianID: String
        var notes: String
        var budget: Double
        var ownerID: String
        var ratio: Double
        var refills: Int
        var status: InventoryEntryStatus

        init(code: String, label: String, category: String, clinicianID: String, notes: String, budget: Double, ownerID: String, ratio: Double, refills: Int, status: InventoryEntryStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.clinicianID = clinicianID
            self.notes = notes
            self.budget = budget
            self.ownerID = ownerID
            self.ratio = ratio
            self.refills = refills
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

        func canMoveTo(_ next: InventoryEntryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == InventoryEntryStatus.running || next == InventoryEntryStatus.failed
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

        func moveTo(_ next: InventoryEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return ((budget + ratio) * 100).rounded() / 100
        }

        func copyValue() -> InventoryEntry {
            return InventoryEntry(
                code: code,
                label: label,
                category: category,
                clinicianID: clinicianID,
                notes: notes,
                budget: budget,
                ownerID: ownerID,
                ratio: ratio,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a inventory entry in status new.
    static func newInventoryEntry(_ code: String, label: String) -> InventoryEntry {
        return InventoryEntry(
            code: code,
            label: label,
            category: "",
            clinicianID: "",
            notes: "",
            budget: 0.0,
            ownerID: "",
            ratio: 0.0,
            refills: 0,
            status: InventoryEntryStatus.new
        )
    }
}
