import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered outreach entry is in its life cycle.
    enum TieredOutreachEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One tiered outreach entry, with what the planners need to act on it.
    final class TieredOutreachEntry {
        var code: String
        var name: String
        var acuity: Int
        var attempts: Int
        var channel: String
        var status: TieredOutreachEntryStatus

        init(code: String, name: String, acuity: Int, attempts: Int, channel: String, status: TieredOutreachEntryStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.attempts = attempts
            self.channel = channel
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

        func canMoveTo(_ next: TieredOutreachEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == TieredOutreachEntryStatus.published || next == TieredOutreachEntryStatus.retired
            case .published:
                return next == TieredOutreachEntryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredOutreachEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered outreach entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered outreach entry") \(code)"
        }

        func netValue() -> Double {
            return (Double(acuity) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> TieredOutreachEntry {
            return TieredOutreachEntry(
                code: code,
                name: name,
                acuity: acuity,
                attempts: attempts,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a tiered outreach entry in status created.
    static func newTieredOutreachEntry(_ code: String, name: String) -> TieredOutreachEntry {
        return TieredOutreachEntry(
            code: code,
            name: name,
            acuity: 0,
            attempts: 0,
            channel: "",
            status: TieredOutreachEntryStatus.created
        )
    }
}
