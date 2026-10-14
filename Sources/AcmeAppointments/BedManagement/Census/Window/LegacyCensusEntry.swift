import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy census entry is in its life cycle.
    enum LegacyCensusEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy census entry as the census team keeps it.
    final class LegacyCensusEntry {
        var code: String
        var label: String
        var margin: Double
        var encounterID: String
        var reviewer: String
        var status: LegacyCensusEntryStatus

        init(code: String, label: String, margin: Double, encounterID: String, reviewer: String, status: LegacyCensusEntryStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCensusEntryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LegacyCensusEntryStatus.ready || next == LegacyCensusEntryStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LegacyCensusEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy census entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy census entry") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> LegacyCensusEntry {
            return LegacyCensusEntry(
                code: code,
                label: label,
                margin: margin,
                encounterID: encounterID,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy census entry in status idle.
    static func newLegacyCensusEntry(_ code: String, label: String) -> LegacyCensusEntry {
        return LegacyCensusEntry(
            code: code,
            label: label,
            margin: 0.0,
            encounterID: "",
            reviewer: "",
            status: LegacyCensusEntryStatus.idle
        )
    }
}
