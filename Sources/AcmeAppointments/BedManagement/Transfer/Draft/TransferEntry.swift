import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer entry is in its life cycle.
    enum TransferEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A transfer entry as the transfer team keeps it.
    final class TransferEntry {
        var code: String
        var label: String
        var bed: String
        var priority: Int
        var version: Int
        var timezone: String
        var limit: Int
        var channel: String
        var status: TransferEntryStatus

        init(code: String, label: String, bed: String, priority: Int, version: Int, timezone: String, limit: Int, channel: String, status: TransferEntryStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.priority = priority
            self.version = version
            self.timezone = timezone
            self.limit = limit
            self.channel = channel
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

        func canMoveTo(_ next: TransferEntryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: TransferEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((Double(priority) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> TransferEntry {
            return TransferEntry(
                code: code,
                label: label,
                bed: bed,
                priority: priority,
                version: version,
                timezone: timezone,
                limit: limit,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a transfer entry in status new.
    static func newTransferEntry(_ code: String, label: String) -> TransferEntry {
        return TransferEntry(
            code: code,
            label: label,
            bed: "",
            priority: 0,
            version: 0,
            timezone: "",
            limit: 0,
            channel: "",
            status: TransferEntryStatus.new
        )
    }
}
