import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped transfer baseline is in its life cycle.
    enum CappedTransferBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped transfer baseline. Its code is unique within a tenant.
    final class CappedTransferBaseline {
        var code: String
        var title: String
        var capacity: Int
        var checksum: String
        var batchSize: Int
        var status: CappedTransferBaselineStatus

        init(code: String, title: String, capacity: Int, checksum: String, batchSize: Int, status: CappedTransferBaselineStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.checksum = checksum
            self.batchSize = batchSize
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

        func canMoveTo(_ next: CappedTransferBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedTransferBaselineStatus.published || next == CappedTransferBaselineStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CappedTransferBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedTransferBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped transfer baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(batchSize) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedTransferBaseline {
            return CappedTransferBaseline(
                code: code,
                title: title,
                capacity: capacity,
                checksum: checksum,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped transfer baseline in status created.
    static func newCappedTransferBaseline(_ code: String, title: String) -> CappedTransferBaseline {
        return CappedTransferBaseline(
            code: code,
            title: title,
            capacity: 0,
            checksum: "",
            batchSize: 0,
            status: CappedTransferBaselineStatus.created
        )
    }
}
