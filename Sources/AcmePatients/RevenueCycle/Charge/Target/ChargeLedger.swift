import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge ledger is in its life cycle.
    enum ChargeLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A charge ledger. Its code is unique within a tenant.
    final class ChargeLedger {
        var code: String
        var title: String
        var endsAt: Int
        var notes: String
        var summary: String
        var ward: String
        var checksum: String
        var cost: Double
        var rate: Double
        var payer: String
        var source: String
        var status: ChargeLedgerStatus

        init(code: String, title: String, endsAt: Int, notes: String, summary: String, ward: String, checksum: String, cost: Double, rate: Double, payer: String, source: String, status: ChargeLedgerStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.notes = notes
            self.summary = summary
            self.ward = ward
            self.checksum = checksum
            self.cost = cost
            self.rate = rate
            self.payer = payer
            self.source = source
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

        func canMoveTo(_ next: ChargeLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ChargeLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedExposure() -> Double {
            return (Double(endsAt) * rate * 100).rounded() / 100
        }

        func copyValue() -> ChargeLedger {
            return ChargeLedger(
                code: code,
                title: title,
                endsAt: endsAt,
                notes: notes,
                summary: summary,
                ward: ward,
                checksum: checksum,
                cost: cost,
                rate: rate,
                payer: payer,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a charge ledger in status created.
    static func newChargeLedger(_ code: String, title: String) -> ChargeLedger {
        return ChargeLedger(
            code: code,
            title: title,
            endsAt: 0,
            notes: "",
            summary: "",
            ward: "",
            checksum: "",
            cost: 0.0,
            rate: 0.0,
            payer: "",
            source: "",
            status: ChargeLedgerStatus.created
        )
    }
}
