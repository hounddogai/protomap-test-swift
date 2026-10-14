import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending accession metric is in its life cycle.
    enum PendingAccessionMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One pending accession metric, with what the planners need to act on it.
    final class PendingAccessionMetric {
        var code: String
        var label: String
        var notes: String
        var title: String
        var checksum: String
        var pinned: Bool
        var capacity: Int
        var priority: Int
        var version: Int
        var status: PendingAccessionMetricStatus

        init(code: String, label: String, notes: String, title: String, checksum: String, pinned: Bool, capacity: Int, priority: Int, version: Int, status: PendingAccessionMetricStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.title = title
            self.checksum = checksum
            self.pinned = pinned
            self.capacity = capacity
            self.priority = priority
            self.version = version
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

        func canMoveTo(_ next: PendingAccessionMetricStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PendingAccessionMetricStatus.suspended
            case .suspended:
                return next == PendingAccessionMetricStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingAccessionMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending accession metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PendingAccessionMetric {
            return PendingAccessionMetric(
                code: code,
                label: label,
                notes: notes,
                title: title,
                checksum: checksum,
                pinned: pinned,
                capacity: capacity,
                priority: priority,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending accession metric in status draft.
    static func newPendingAccessionMetric(_ code: String, label: String) -> PendingAccessionMetric {
        return PendingAccessionMetric(
            code: code,
            label: label,
            notes: "",
            title: "",
            checksum: "",
            pinned: false,
            capacity: 0,
            priority: 0,
            version: 0,
            status: PendingAccessionMetricStatus.draft
        )
    }
}
