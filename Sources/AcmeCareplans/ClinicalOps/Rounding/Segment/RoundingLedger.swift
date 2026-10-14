import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding ledger is in its life cycle.
    enum RoundingLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One rounding ledger, with what the planners need to act on it.
    final class RoundingLedger {
        var code: String
        var label: String
        var phone: String
        var batchSize: Int
        var archived: Bool
        var region: String
        var expiresAt: Int
        var payer: String
        var tags: [String]
        var refills: Int
        var status: RoundingLedgerStatus

        init(code: String, label: String, phone: String, batchSize: Int, archived: Bool, region: String, expiresAt: Int, payer: String, tags: [String], refills: Int, status: RoundingLedgerStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.batchSize = batchSize
            self.archived = archived
            self.region = region
            self.expiresAt = expiresAt
            self.payer = payer
            self.tags = tags
            self.refills = refills
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

        func canMoveTo(_ next: RoundingLedgerStatus) -> Bool {
            switch status {
            case .requested:
                return next == RoundingLedgerStatus.revoked || next == RoundingLedgerStatus.expired
            case .granted:
                return next == RoundingLedgerStatus.revoked
            case .revoked:
                return next == RoundingLedgerStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingLedger {
            return RoundingLedger(
                code: code,
                label: label,
                phone: phone,
                batchSize: batchSize,
                archived: archived,
                region: region,
                expiresAt: expiresAt,
                payer: payer,
                tags: tags,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rounding ledger in status requested.
    static func newRoundingLedger(_ code: String, label: String) -> RoundingLedger {
        return RoundingLedger(
            code: code,
            label: label,
            phone: "",
            batchSize: 0,
            archived: false,
            region: "",
            expiresAt: 0,
            payer: "",
            tags: [],
            refills: 0,
            status: RoundingLedgerStatus.requested
        )
    }
}
