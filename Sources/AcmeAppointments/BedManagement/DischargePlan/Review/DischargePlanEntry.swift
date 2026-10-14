import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan entry is in its life cycle.
    enum DischargePlanEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a discharge plan entry and its current status.
    final class DischargePlanEntry {
        var code: String
        var label: String
        var currency: String
        var createdAt: Int
        var floorValue: Double
        var notes: String
        var approved: Bool
        var updatedAt: Int
        var status: DischargePlanEntryStatus

        init(code: String, label: String, currency: String, createdAt: Int, floorValue: Double, notes: String, approved: Bool, updatedAt: Int, status: DischargePlanEntryStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.notes = notes
            self.approved = approved
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: DischargePlanEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == DischargePlanEntryStatus.queued || next == DischargePlanEntryStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == DischargePlanEntryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(updatedAt) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanEntry {
            return DischargePlanEntry(
                code: code,
                label: label,
                currency: currency,
                createdAt: createdAt,
                floorValue: floorValue,
                notes: notes,
                approved: approved,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a discharge plan entry in status new.
    static func newDischargePlanEntry(_ code: String, label: String) -> DischargePlanEntry {
        return DischargePlanEntry(
            code: code,
            label: label,
            currency: "",
            createdAt: 0,
            floorValue: 0.0,
            notes: "",
            approved: false,
            updatedAt: 0,
            status: DischargePlanEntryStatus.new
        )
    }
}
