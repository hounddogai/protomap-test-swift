import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending handoff ledger is in its life cycle.
    enum PendingHandoffLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One pending handoff ledger, with what the planners need to act on it.
    final class PendingHandoffLedger {
        var code: String
        var title: String
        var specialty: String
        var updatedAt: Int
        var endsAt: Int
        var quantity: Int
        var graceDays: Int
        var clinicianID: String
        var revision: Int
        var country: String
        var status: PendingHandoffLedgerStatus

        init(code: String, title: String, specialty: String, updatedAt: Int, endsAt: Int, quantity: Int, graceDays: Int, clinicianID: String, revision: Int, country: String, status: PendingHandoffLedgerStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.endsAt = endsAt
            self.quantity = quantity
            self.graceDays = graceDays
            self.clinicianID = clinicianID
            self.revision = revision
            self.country = country
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

        func canMoveTo(_ next: PendingHandoffLedgerStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingHandoffLedgerStatus.granted || next == PendingHandoffLedgerStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PendingHandoffLedgerStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingHandoffLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending handoff ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("pending handoff ledger") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(revision) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> PendingHandoffLedger {
            return PendingHandoffLedger(
                code: code,
                title: title,
                specialty: specialty,
                updatedAt: updatedAt,
                endsAt: endsAt,
                quantity: quantity,
                graceDays: graceDays,
                clinicianID: clinicianID,
                revision: revision,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending handoff ledger in status requested.
    static func newPendingHandoffLedger(_ code: String, title: String) -> PendingHandoffLedger {
        return PendingHandoffLedger(
            code: code,
            title: title,
            specialty: "",
            updatedAt: 0,
            endsAt: 0,
            quantity: 0,
            graceDays: 0,
            clinicianID: "",
            revision: 0,
            country: "",
            status: PendingHandoffLedgerStatus.requested
        )
    }
}
