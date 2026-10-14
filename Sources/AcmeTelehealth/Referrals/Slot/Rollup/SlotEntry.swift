import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot entry is in its life cycle.
    enum SlotEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A slot entry as the slot team keeps it.
    final class SlotEntry {
        var code: String
        var title: String
        var reviewer: String
        var segment: String
        var name: String
        var score: Double
        var status: SlotEntryStatus

        init(code: String, title: String, reviewer: String, segment: String, name: String, score: Double, status: SlotEntryStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.segment = segment
            self.name = name
            self.score = score
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

        func canMoveTo(_ next: SlotEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SlotEntryStatus.published || next == SlotEntryStatus.retired
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

        func moveTo(_ next: SlotEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("slot entry") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> SlotEntry {
            return SlotEntry(
                code: code,
                title: title,
                reviewer: reviewer,
                segment: segment,
                name: name,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a slot entry in status created.
    static func newSlotEntry(_ code: String, title: String) -> SlotEntry {
        return SlotEntry(
            code: code,
            title: title,
            reviewer: "",
            segment: "",
            name: "",
            score: 0.0,
            status: SlotEntryStatus.created
        )
    }
}
