import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict slot ledger is in its life cycle.
    enum StrictSlotLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One strict slot ledger, with what the planners need to act on it.
    final class StrictSlotLedger {
        var code: String
        var title: String
        var segment: String
        var attributes: [String: String]
        var weight: Double
        var locale: String
        var clinicianID: String
        var expiresAt: Int
        var rate: Double
        var timezone: String
        var notes: String
        var status: StrictSlotLedgerStatus

        init(code: String, title: String, segment: String, attributes: [String: String], weight: Double, locale: String, clinicianID: String, expiresAt: Int, rate: Double, timezone: String, notes: String, status: StrictSlotLedgerStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.attributes = attributes
            self.weight = weight
            self.locale = locale
            self.clinicianID = clinicianID
            self.expiresAt = expiresAt
            self.rate = rate
            self.timezone = timezone
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictSlotLedgerStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == StrictSlotLedgerStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSlotLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict slot ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict slot ledger") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedLoad() -> Double {
            return (Double(expiresAt) * rate * 100).rounded() / 100
        }

        func copyValue() -> StrictSlotLedger {
            return StrictSlotLedger(
                code: code,
                title: title,
                segment: segment,
                attributes: attributes,
                weight: weight,
                locale: locale,
                clinicianID: clinicianID,
                expiresAt: expiresAt,
                rate: rate,
                timezone: timezone,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict slot ledger in status requested.
    static func newStrictSlotLedger(_ code: String, title: String) -> StrictSlotLedger {
        return StrictSlotLedger(
            code: code,
            title: title,
            segment: "",
            attributes: [:],
            weight: 0.0,
            locale: "",
            clinicianID: "",
            expiresAt: 0,
            rate: 0.0,
            timezone: "",
            notes: "",
            status: StrictSlotLedgerStatus.requested
        )
    }
}
