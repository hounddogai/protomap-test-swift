import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network batch is in its life cycle.
    enum NetworkBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A network batch. Its code is unique within a tenant.
    final class NetworkBatch {
        var code: String
        var label: String
        var ceiling: Double
        var archived: Bool
        var encounterID: String
        var reviewer: String
        var rate: Double
        var ownerID: String
        var notes: String
        var windowDays: Int
        var status: NetworkBatchStatus

        init(code: String, label: String, ceiling: Double, archived: Bool, encounterID: String, reviewer: String, rate: Double, ownerID: String, notes: String, windowDays: Int, status: NetworkBatchStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.archived = archived
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.rate = rate
            self.ownerID = ownerID
            self.notes = notes
            self.windowDays = windowDays
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

        func canMoveTo(_ next: NetworkBatchStatus) -> Bool {
            switch status {
            case .`open`:
                return next == NetworkBatchStatus.resolved
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == NetworkBatchStatus.reopened || next == NetworkBatchStatus.archived
            case .reopened:
                return next == NetworkBatchStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((ceiling - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkBatch {
            return NetworkBatch(
                code: code,
                label: label,
                ceiling: ceiling,
                archived: archived,
                encounterID: encounterID,
                reviewer: reviewer,
                rate: rate,
                ownerID: ownerID,
                notes: notes,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a network batch in status open.
    static func newNetworkBatch(_ code: String, label: String) -> NetworkBatch {
        return NetworkBatch(
            code: code,
            label: label,
            ceiling: 0.0,
            archived: false,
            encounterID: "",
            reviewer: "",
            rate: 0.0,
            ownerID: "",
            notes: "",
            windowDays: 0,
            status: NetworkBatchStatus.`open`
        )
    }
}
