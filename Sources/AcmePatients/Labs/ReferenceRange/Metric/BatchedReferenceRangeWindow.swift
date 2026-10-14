import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched reference range window is in its life cycle.
    enum BatchedReferenceRangeWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One batched reference range window, with what the planners need to act on it.
    final class BatchedReferenceRangeWindow {
        var code: String
        var title: String
        var notes: String
        var batchSize: Int
        var encounterID: String
        var tags: [String]
        var acuity: Int
        var revision: Int
        var ceiling: Double
        var status: BatchedReferenceRangeWindowStatus

        init(code: String, title: String, notes: String, batchSize: Int, encounterID: String, tags: [String], acuity: Int, revision: Int, ceiling: Double, status: BatchedReferenceRangeWindowStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.batchSize = batchSize
            self.encounterID = encounterID
            self.tags = tags
            self.acuity = acuity
            self.revision = revision
            self.ceiling = ceiling
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

        func canMoveTo(_ next: BatchedReferenceRangeWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedReferenceRangeWindowStatus.validated || next == BatchedReferenceRangeWindowStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == BatchedReferenceRangeWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedReferenceRangeWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched reference range window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return ((Double(batchSize) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedReferenceRangeWindow {
            return BatchedReferenceRangeWindow(
                code: code,
                title: title,
                notes: notes,
                batchSize: batchSize,
                encounterID: encounterID,
                tags: tags,
                acuity: acuity,
                revision: revision,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched reference range window in status created.
    static func newBatchedReferenceRangeWindow(_ code: String, title: String) -> BatchedReferenceRangeWindow {
        return BatchedReferenceRangeWindow(
            code: code,
            title: title,
            notes: "",
            batchSize: 0,
            encounterID: "",
            tags: [],
            acuity: 0,
            revision: 0,
            ceiling: 0.0,
            status: BatchedReferenceRangeWindowStatus.created
        )
    }
}
