import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction ledger is in its life cycle.
    enum InteractionLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A interaction ledger. Its code is unique within a tenant.
    final class InteractionLedger {
        var code: String
        var name: String
        var version: Int
        var notes: String
        var copay: Double
        var status: InteractionLedgerStatus

        init(code: String, name: String, version: Int, notes: String, copay: Double, status: InteractionLedgerStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.notes = notes
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == InteractionLedgerStatus.resolved || next == InteractionLedgerStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == InteractionLedgerStatus.archived
            case .reopened:
                return next == InteractionLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("interaction ledger") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(version) * copay * 100).rounded() / 100
        }

        func copyValue() -> InteractionLedger {
            return InteractionLedger(
                code: code,
                name: name,
                version: version,
                notes: notes,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction ledger in status open.
    static func newInteractionLedger(_ code: String, name: String) -> InteractionLedger {
        return InteractionLedger(
            code: code,
            name: name,
            version: 0,
            notes: "",
            copay: 0.0,
            status: InteractionLedgerStatus.`open`
        )
    }
}
