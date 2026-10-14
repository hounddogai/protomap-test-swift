import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped modality batch is in its life cycle.
    enum CappedModalityBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One capped modality batch, with what the planners need to act on it.
    final class CappedModalityBatch {
        var code: String
        var name: String
        var channel: String
        var updatedAt: Int
        var allergy: String
        var expiresAt: Int
        var status: CappedModalityBatchStatus

        init(code: String, name: String, channel: String, updatedAt: Int, allergy: String, expiresAt: Int, status: CappedModalityBatchStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.updatedAt = updatedAt
            self.allergy = allergy
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CappedModalityBatchStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CappedModalityBatchStatus.suspended || next == CappedModalityBatchStatus.closed
            case .suspended:
                return next == CappedModalityBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedModalityBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped modality batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return ((Double(updatedAt) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedModalityBatch {
            return CappedModalityBatch(
                code: code,
                name: name,
                channel: channel,
                updatedAt: updatedAt,
                allergy: allergy,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped modality batch in status draft.
    static func newCappedModalityBatch(_ code: String, name: String) -> CappedModalityBatch {
        return CappedModalityBatch(
            code: code,
            name: name,
            channel: "",
            updatedAt: 0,
            allergy: "",
            expiresAt: 0,
            status: CappedModalityBatchStatus.draft
        )
    }
}
