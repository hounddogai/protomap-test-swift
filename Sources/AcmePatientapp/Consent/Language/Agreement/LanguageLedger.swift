import AcmePlatform
import Foundation

extension Consent {
    /// Where a language ledger is in its life cycle.
    enum LanguageLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A language ledger. Its code is unique within a tenant.
    final class LanguageLedger {
        var code: String
        var name: String
        var updatedAt: Int
        var tags: [String]
        var currency: String
        var batchSize: Int
        var externalRef: String
        var reviewer: String
        var durationMinutes: Int
        var allergy: String
        var locale: String
        var status: LanguageLedgerStatus

        init(code: String, name: String, updatedAt: Int, tags: [String], currency: String, batchSize: Int, externalRef: String, reviewer: String, durationMinutes: Int, allergy: String, locale: String, status: LanguageLedgerStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.tags = tags
            self.currency = currency
            self.batchSize = batchSize
            self.externalRef = externalRef
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.allergy = allergy
            self.locale = locale
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

        func canMoveTo(_ next: LanguageLedgerStatus) -> Bool {
            switch status {
            case .requested:
                return next == LanguageLedgerStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LanguageLedgerStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("language ledger") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return (Double(batchSize) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> LanguageLedger {
            return LanguageLedger(
                code: code,
                name: name,
                updatedAt: updatedAt,
                tags: tags,
                currency: currency,
                batchSize: batchSize,
                externalRef: externalRef,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                allergy: allergy,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a language ledger in status requested.
    static func newLanguageLedger(_ code: String, name: String) -> LanguageLedger {
        return LanguageLedger(
            code: code,
            name: name,
            updatedAt: 0,
            tags: [],
            currency: "",
            batchSize: 0,
            externalRef: "",
            reviewer: "",
            durationMinutes: 0,
            allergy: "",
            locale: "",
            status: LanguageLedgerStatus.requested
        )
    }
}
