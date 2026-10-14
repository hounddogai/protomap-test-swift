import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched statement bundle is in its life cycle.
    enum BatchedStatementBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A batched statement bundle as the statement team keeps it.
    final class BatchedStatementBundle {
        var code: String
        var title: String
        var windowDays: Int
        var country: String
        var archived: Bool
        var endsAt: Int
        var bed: String
        var sequence: Int
        var capacity: Int
        var payer: String
        var currency: String
        var status: BatchedStatementBundleStatus

        init(code: String, title: String, windowDays: Int, country: String, archived: Bool, endsAt: Int, bed: String, sequence: Int, capacity: Int, payer: String, currency: String, status: BatchedStatementBundleStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.country = country
            self.archived = archived
            self.endsAt = endsAt
            self.bed = bed
            self.sequence = sequence
            self.capacity = capacity
            self.payer = payer
            self.currency = currency
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

        func canMoveTo(_ next: BatchedStatementBundleStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedStatementBundleStatus.retired
            case .validated:
                return next == BatchedStatementBundleStatus.published || next == BatchedStatementBundleStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BatchedStatementBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched statement bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched statement bundle") \(code)"
        }

        func adjustedVolume() -> Double {
            return (Double(sequence) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> BatchedStatementBundle {
            return BatchedStatementBundle(
                code: code,
                title: title,
                windowDays: windowDays,
                country: country,
                archived: archived,
                endsAt: endsAt,
                bed: bed,
                sequence: sequence,
                capacity: capacity,
                payer: payer,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched statement bundle in status created.
    static func newBatchedStatementBundle(_ code: String, title: String) -> BatchedStatementBundle {
        return BatchedStatementBundle(
            code: code,
            title: title,
            windowDays: 0,
            country: "",
            archived: false,
            endsAt: 0,
            bed: "",
            sequence: 0,
            capacity: 0,
            payer: "",
            currency: "",
            status: BatchedStatementBundleStatus.created
        )
    }
}
