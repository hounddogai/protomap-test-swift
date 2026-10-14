import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer summary is in its life cycle.
    enum TransferSummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a transfer summary and its current status.
    final class TransferSummary {
        var code: String
        var title: String
        var active: Bool
        var checksum: String
        var limit: Int
        var expiresAt: Int
        var amount: Double
        var updatedAt: Int
        var payer: String
        var createdAt: Int
        var cost: Double
        var status: TransferSummaryStatus

        init(code: String, title: String, active: Bool, checksum: String, limit: Int, expiresAt: Int, amount: Double, updatedAt: Int, payer: String, createdAt: Int, cost: Double, status: TransferSummaryStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.checksum = checksum
            self.limit = limit
            self.expiresAt = expiresAt
            self.amount = amount
            self.updatedAt = updatedAt
            self.payer = payer
            self.createdAt = createdAt
            self.cost = cost
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

        func canMoveTo(_ next: TransferSummaryStatus) -> Bool {
            switch status {
            case .planned:
                return next == TransferSummaryStatus.scheduled || next == TransferSummaryStatus.cancelled
            case .scheduled:
                return next == TransferSummaryStatus.completed
            case .inProgress:
                return next == TransferSummaryStatus.completed || next == TransferSummaryStatus.cancelled
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

        func moveTo(_ next: TransferSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedLoad() -> Double {
            return ((Double(limit) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> TransferSummary {
            return TransferSummary(
                code: code,
                title: title,
                active: active,
                checksum: checksum,
                limit: limit,
                expiresAt: expiresAt,
                amount: amount,
                updatedAt: updatedAt,
                payer: payer,
                createdAt: createdAt,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a transfer summary in status planned.
    static func newTransferSummary(_ code: String, title: String) -> TransferSummary {
        return TransferSummary(
            code: code,
            title: title,
            active: false,
            checksum: "",
            limit: 0,
            expiresAt: 0,
            amount: 0.0,
            updatedAt: 0,
            payer: "",
            createdAt: 0,
            cost: 0.0,
            status: TransferSummaryStatus.planned
        )
    }
}
