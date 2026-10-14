import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered handoff ledger is in its life cycle.
    enum TieredHandoffLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered handoff ledger and its current status.
    final class TieredHandoffLedger {
        var code: String
        var name: String
        var tags: [String]
        var checksum: String
        var phone: String
        var floorValue: Double
        var status: TieredHandoffLedgerStatus

        init(code: String, name: String, tags: [String], checksum: String, phone: String, floorValue: Double, status: TieredHandoffLedgerStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.checksum = checksum
            self.phone = phone
            self.floorValue = floorValue
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

        func canMoveTo(_ next: TieredHandoffLedgerStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredHandoffLedgerStatus.pending || next == TieredHandoffLedgerStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TieredHandoffLedgerStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TieredHandoffLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered handoff ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> TieredHandoffLedger {
            return TieredHandoffLedger(
                code: code,
                name: name,
                tags: tags,
                checksum: checksum,
                phone: phone,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered handoff ledger in status draft.
    static func newTieredHandoffLedger(_ code: String, name: String) -> TieredHandoffLedger {
        return TieredHandoffLedger(
            code: code,
            name: name,
            tags: [],
            checksum: "",
            phone: "",
            floorValue: 0.0,
            status: TieredHandoffLedgerStatus.draft
        )
    }
}
