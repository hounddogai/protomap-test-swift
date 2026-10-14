import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer record is in its life cycle.
    enum TransferRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One transfer record, with what the planners need to act on it.
    final class TransferRecord {
        var code: String
        var label: String
        var attempts: Int
        var category: String
        var archived: Bool
        var status: TransferRecordStatus

        init(code: String, label: String, attempts: Int, category: String, archived: Bool, status: TransferRecordStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.category = category
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferRecordStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TransferRecordStatus.running || next == TransferRecordStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: TransferRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("transfer record") \(code)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> TransferRecord {
            return TransferRecord(
                code: code,
                label: label,
                attempts: attempts,
                category: category,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a transfer record in status new.
    static func newTransferRecord(_ code: String, label: String) -> TransferRecord {
        return TransferRecord(
            code: code,
            label: label,
            attempts: 0,
            category: "",
            archived: false,
            status: TransferRecordStatus.new
        )
    }
}
