import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched reference range record is in its life cycle.
    enum BatchedReferenceRangeRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched reference range record. Its code is unique within a tenant.
    final class BatchedReferenceRangeRecord {
        var code: String
        var title: String
        var approved: Bool
        var margin: Double
        var ratio: Double
        var status: BatchedReferenceRangeRecordStatus

        init(code: String, title: String, approved: Bool, margin: Double, ratio: Double, status: BatchedReferenceRangeRecordStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.margin = margin
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedReferenceRangeRecordStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedReferenceRangeRecordStatus.expired
            case .revoked:
                return next == BatchedReferenceRangeRecordStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedReferenceRangeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched reference range record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return ((ratio - margin) * 100).rounded() / 100
        }

        func copyValue() -> BatchedReferenceRangeRecord {
            return BatchedReferenceRangeRecord(
                code: code,
                title: title,
                approved: approved,
                margin: margin,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched reference range record in status requested.
    static func newBatchedReferenceRangeRecord(_ code: String, title: String) -> BatchedReferenceRangeRecord {
        return BatchedReferenceRangeRecord(
            code: code,
            title: title,
            approved: false,
            margin: 0.0,
            ratio: 0.0,
            status: BatchedReferenceRangeRecordStatus.requested
        )
    }
}
