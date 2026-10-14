import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered network entry is in its life cycle.
    enum TieredNetworkEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered network entry and its current status.
    final class TieredNetworkEntry {
        var code: String
        var title: String
        var locale: String
        var attempts: Int
        var endsAt: Int
        var notes: String
        var checksum: String
        var ownerID: String
        var allergy: String
        var clinicianID: String
        var status: TieredNetworkEntryStatus

        init(code: String, title: String, locale: String, attempts: Int, endsAt: Int, notes: String, checksum: String, ownerID: String, allergy: String, clinicianID: String, status: TieredNetworkEntryStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.attempts = attempts
            self.endsAt = endsAt
            self.notes = notes
            self.checksum = checksum
            self.ownerID = ownerID
            self.allergy = allergy
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredNetworkEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TieredNetworkEntryStatus.active || next == TieredNetworkEntryStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredNetworkEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredNetworkEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered network entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(attempts) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredNetworkEntry {
            return TieredNetworkEntry(
                code: code,
                title: title,
                locale: locale,
                attempts: attempts,
                endsAt: endsAt,
                notes: notes,
                checksum: checksum,
                ownerID: ownerID,
                allergy: allergy,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a tiered network entry in status draft.
    static func newTieredNetworkEntry(_ code: String, title: String) -> TieredNetworkEntry {
        return TieredNetworkEntry(
            code: code,
            title: title,
            locale: "",
            attempts: 0,
            endsAt: 0,
            notes: "",
            checksum: "",
            ownerID: "",
            allergy: "",
            clinicianID: "",
            status: TieredNetworkEntryStatus.draft
        )
    }
}
