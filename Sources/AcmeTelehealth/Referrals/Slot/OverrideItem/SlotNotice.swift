import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot notice is in its life cycle.
    enum SlotNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One slot notice, with what the planners need to act on it.
    final class SlotNotice {
        var code: String
        var title: String
        var graceDays: Int
        var encounterID: String
        var version: Int
        var contactEmail: String
        var label: String
        var procedureCode: String
        var durationMinutes: Int
        var rate: Double
        var status: SlotNoticeStatus

        init(code: String, title: String, graceDays: Int, encounterID: String, version: Int, contactEmail: String, label: String, procedureCode: String, durationMinutes: Int, rate: Double, status: SlotNoticeStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.encounterID = encounterID
            self.version = version
            self.contactEmail = contactEmail
            self.label = label
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.rate = rate
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

        func canMoveTo(_ next: SlotNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SlotNoticeStatus.failed
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

        func moveTo(_ next: SlotNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((rate - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SlotNotice {
            return SlotNotice(
                code: code,
                title: title,
                graceDays: graceDays,
                encounterID: encounterID,
                version: version,
                contactEmail: contactEmail,
                label: label,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a slot notice in status new.
    static func newSlotNotice(_ code: String, title: String) -> SlotNotice {
        return SlotNotice(
            code: code,
            title: title,
            graceDays: 0,
            encounterID: "",
            version: 0,
            contactEmail: "",
            label: "",
            procedureCode: "",
            durationMinutes: 0,
            rate: 0.0,
            status: SlotNoticeStatus.new
        )
    }
}
