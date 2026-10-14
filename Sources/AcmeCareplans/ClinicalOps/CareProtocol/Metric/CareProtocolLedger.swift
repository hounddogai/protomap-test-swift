import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol ledger is in its life cycle.
    enum CareProtocolLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One care protocol ledger, with what the planners need to act on it.
    final class CareProtocolLedger {
        var code: String
        var name: String
        var retries: Int
        var archived: Bool
        var startsAt: Int
        var status: CareProtocolLedgerStatus

        init(code: String, name: String, retries: Int, archived: Bool, startsAt: Int, status: CareProtocolLedgerStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.archived = archived
            self.startsAt = startsAt
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

        func canMoveTo(_ next: CareProtocolLedgerStatus) -> Bool {
            switch status {
            case .planned:
                return next == CareProtocolLedgerStatus.scheduled || next == CareProtocolLedgerStatus.cancelled
            case .scheduled:
                return next == CareProtocolLedgerStatus.completed || next == CareProtocolLedgerStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CareProtocolLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return (Double(startsAt) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolLedger {
            return CareProtocolLedger(
                code: code,
                name: name,
                retries: retries,
                archived: archived,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol ledger in status planned.
    static func newCareProtocolLedger(_ code: String, name: String) -> CareProtocolLedger {
        return CareProtocolLedger(
            code: code,
            name: name,
            retries: 0,
            archived: false,
            startsAt: 0,
            status: CareProtocolLedgerStatus.planned
        )
    }
}
