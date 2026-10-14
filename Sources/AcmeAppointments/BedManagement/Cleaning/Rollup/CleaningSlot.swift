import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning slot is in its life cycle.
    enum CleaningSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A cleaning slot as the cleaning team keeps it.
    final class CleaningSlot {
        var code: String
        var label: String
        var currency: String
        var encounterID: String
        var score: Double
        var summary: String
        var margin: Double
        var startsAt: Int
        var dosageMg: Double
        var pinned: Bool
        var budget: Double
        var status: CleaningSlotStatus

        init(code: String, label: String, currency: String, encounterID: String, score: Double, summary: String, margin: Double, startsAt: Int, dosageMg: Double, pinned: Bool, budget: Double, status: CleaningSlotStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.encounterID = encounterID
            self.score = score
            self.summary = summary
            self.margin = margin
            self.startsAt = startsAt
            self.dosageMg = dosageMg
            self.pinned = pinned
            self.budget = budget
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

        func canMoveTo(_ next: CleaningSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == CleaningSlotStatus.done || next == CleaningSlotStatus.failed
            case .queued:
                switch next {
                case .done:
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

        func moveTo(_ next: CleaningSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("cleaning slot") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(startsAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> CleaningSlot {
            return CleaningSlot(
                code: code,
                label: label,
                currency: currency,
                encounterID: encounterID,
                score: score,
                summary: summary,
                margin: margin,
                startsAt: startsAt,
                dosageMg: dosageMg,
                pinned: pinned,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a cleaning slot in status new.
    static func newCleaningSlot(_ code: String, label: String) -> CleaningSlot {
        return CleaningSlot(
            code: code,
            label: label,
            currency: "",
            encounterID: "",
            score: 0.0,
            summary: "",
            margin: 0.0,
            startsAt: 0,
            dosageMg: 0.0,
            pinned: false,
            budget: 0.0,
            status: CleaningSlotStatus.new
        )
    }
}
