import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy closure ledger is in its life cycle.
    enum LegacyClosureLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One legacy closure ledger, with what the planners need to act on it.
    final class LegacyClosureLedger {
        var code: String
        var name: String
        var ceiling: Double
        var tags: [String]
        var region: String
        var rate: Double
        var endsAt: Int
        var status: LegacyClosureLedgerStatus

        init(code: String, name: String, ceiling: Double, tags: [String], region: String, rate: Double, endsAt: Int, status: LegacyClosureLedgerStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.tags = tags
            self.region = region
            self.rate = rate
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyClosureLedgerStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyClosureLedgerStatus.warming
            case .warming:
                return next == LegacyClosureLedgerStatus.ready
            case .ready:
                return next == LegacyClosureLedgerStatus.draining || next == LegacyClosureLedgerStatus.stopped
            case .draining:
                return next == LegacyClosureLedgerStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyClosureLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy closure ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy closure ledger") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((rate + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyClosureLedger {
            return LegacyClosureLedger(
                code: code,
                name: name,
                ceiling: ceiling,
                tags: tags,
                region: region,
                rate: rate,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy closure ledger in status idle.
    static func newLegacyClosureLedger(_ code: String, name: String) -> LegacyClosureLedger {
        return LegacyClosureLedger(
            code: code,
            name: name,
            ceiling: 0.0,
            tags: [],
            region: "",
            rate: 0.0,
            endsAt: 0,
            status: LegacyClosureLedgerStatus.idle
        )
    }
}
