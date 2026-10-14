import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched care gap digest is in its life cycle.
    enum BatchedCareGapDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One batched care gap digest, with what the planners need to act on it.
    final class BatchedCareGapDigest {
        var code: String
        var name: String
        var archived: Bool
        var ward: String
        var ceiling: Double
        var tags: [String]
        var status: BatchedCareGapDigestStatus

        init(code: String, name: String, archived: Bool, ward: String, ceiling: Double, tags: [String], status: BatchedCareGapDigestStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.ward = ward
            self.ceiling = ceiling
            self.tags = tags
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

        func canMoveTo(_ next: BatchedCareGapDigestStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedCareGapDigestStatus.published || next == BatchedCareGapDigestStatus.retired
            case .validated:
                return next == BatchedCareGapDigestStatus.retired
            case .published:
                return next == BatchedCareGapDigestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCareGapDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care gap digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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
            return ceiling
        }

        func copyValue() -> BatchedCareGapDigest {
            return BatchedCareGapDigest(
                code: code,
                name: name,
                archived: archived,
                ward: ward,
                ceiling: ceiling,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a batched care gap digest in status created.
    static func newBatchedCareGapDigest(_ code: String, name: String) -> BatchedCareGapDigest {
        return BatchedCareGapDigest(
            code: code,
            name: name,
            archived: false,
            ward: "",
            ceiling: 0.0,
            tags: [],
            status: BatchedCareGapDigestStatus.created
        )
    }
}
