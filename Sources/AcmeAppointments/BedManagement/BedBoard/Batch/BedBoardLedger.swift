import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board ledger is in its life cycle.
    enum BedBoardLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a bed board ledger and its current status.
    final class BedBoardLedger {
        var code: String
        var name: String
        var ratio: Double
        var archived: Bool
        var cost: Double
        var score: Double
        var updatedAt: Int
        var status: BedBoardLedgerStatus

        init(code: String, name: String, ratio: Double, archived: Bool, cost: Double, score: Double, updatedAt: Int, status: BedBoardLedgerStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.archived = archived
            self.cost = cost
            self.score = score
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: BedBoardLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BedBoardLedgerStatus.resolved || next == BedBoardLedgerStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: BedBoardLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (score * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardLedger {
            return BedBoardLedger(
                code: code,
                name: name,
                ratio: ratio,
                archived: archived,
                cost: cost,
                score: score,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a bed board ledger in status open.
    static func newBedBoardLedger(_ code: String, name: String) -> BedBoardLedger {
        return BedBoardLedger(
            code: code,
            name: name,
            ratio: 0.0,
            archived: false,
            cost: 0.0,
            score: 0.0,
            updatedAt: 0,
            status: BedBoardLedgerStatus.`open`
        )
    }
}
