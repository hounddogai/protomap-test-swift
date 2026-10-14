import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched care protocol ledger is in its life cycle.
    enum BatchedCareProtocolLedgerStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched care protocol ledger. Its code is unique within a tenant.
    final class BatchedCareProtocolLedger {
        var code: String
        var label: String
        var ownerID: String
        var ratio: Double
        var active: Bool
        var minimum: Double
        var version: Int
        var title: String
        var summary: String
        var encounterID: String
        var tags: [String]
        var status: BatchedCareProtocolLedgerStatus

        init(code: String, label: String, ownerID: String, ratio: Double, active: Bool, minimum: Double, version: Int, title: String, summary: String, encounterID: String, tags: [String], status: BatchedCareProtocolLedgerStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.ratio = ratio
            self.active = active
            self.minimum = minimum
            self.version = version
            self.title = title
            self.summary = summary
            self.encounterID = encounterID
            self.tags = tags
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

        func canMoveTo(_ next: BatchedCareProtocolLedgerStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == BatchedCareProtocolLedgerStatus.draining || next == BatchedCareProtocolLedgerStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedCareProtocolLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care protocol ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((minimum + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareProtocolLedger {
            return BatchedCareProtocolLedger(
                code: code,
                label: label,
                ownerID: ownerID,
                ratio: ratio,
                active: active,
                minimum: minimum,
                version: version,
                title: title,
                summary: summary,
                encounterID: encounterID,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched care protocol ledger in status idle.
    static func newBatchedCareProtocolLedger(_ code: String, label: String) -> BatchedCareProtocolLedger {
        return BatchedCareProtocolLedger(
            code: code,
            label: label,
            ownerID: "",
            ratio: 0.0,
            active: false,
            minimum: 0.0,
            version: 0,
            title: "",
            summary: "",
            encounterID: "",
            tags: [],
            status: BatchedCareProtocolLedgerStatus.idle
        )
    }
}
