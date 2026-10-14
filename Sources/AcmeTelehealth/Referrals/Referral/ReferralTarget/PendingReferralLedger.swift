import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending referral ledger is in its life cycle.
    enum PendingReferralLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending referral ledger as the referral team keeps it.
    final class PendingReferralLedger {
        var code: String
        var label: String
        var cost: Double
        var revision: Int
        var retries: Int
        var title: String
        var endsAt: Int
        var name: String
        var description: String
        var margin: Double
        var unit: String
        var status: PendingReferralLedgerStatus

        init(code: String, label: String, cost: Double, revision: Int, retries: Int, title: String, endsAt: Int, name: String, description: String, margin: Double, unit: String, status: PendingReferralLedgerStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.revision = revision
            self.retries = retries
            self.title = title
            self.endsAt = endsAt
            self.name = name
            self.description = description
            self.margin = margin
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingReferralLedgerStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingReferralLedgerStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingReferralLedgerStatus.cancelled
            case .completed:
                return next == PendingReferralLedgerStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingReferralLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending referral ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((Double(retries) + cost) * 100).rounded() / 100
        }

        func copyValue() -> PendingReferralLedger {
            return PendingReferralLedger(
                code: code,
                label: label,
                cost: cost,
                revision: revision,
                retries: retries,
                title: title,
                endsAt: endsAt,
                name: name,
                description: description,
                margin: margin,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending referral ledger in status planned.
    static func newPendingReferralLedger(_ code: String, label: String) -> PendingReferralLedger {
        return PendingReferralLedger(
            code: code,
            label: label,
            cost: 0.0,
            revision: 0,
            retries: 0,
            title: "",
            endsAt: 0,
            name: "",
            description: "",
            margin: 0.0,
            unit: "",
            status: PendingReferralLedgerStatus.planned
        )
    }
}
