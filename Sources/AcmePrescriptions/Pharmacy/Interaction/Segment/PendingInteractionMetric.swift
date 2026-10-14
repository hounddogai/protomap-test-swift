import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending interaction metric is in its life cycle.
    enum PendingInteractionMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending interaction metric. Its code is unique within a tenant.
    final class PendingInteractionMetric {
        var code: String
        var label: String
        var expiresAt: Int
        var encounterID: String
        var checksum: String
        var archived: Bool
        var pinned: Bool
        var status: PendingInteractionMetricStatus

        init(code: String, label: String, expiresAt: Int, encounterID: String, checksum: String, archived: Bool, pinned: Bool, status: PendingInteractionMetricStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.encounterID = encounterID
            self.checksum = checksum
            self.archived = archived
            self.pinned = pinned
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

        func canMoveTo(_ next: PendingInteractionMetricStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingInteractionMetricStatus.pending
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PendingInteractionMetricStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PendingInteractionMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending interaction metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> PendingInteractionMetric {
            return PendingInteractionMetric(
                code: code,
                label: label,
                expiresAt: expiresAt,
                encounterID: encounterID,
                checksum: checksum,
                archived: archived,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending interaction metric in status draft.
    static func newPendingInteractionMetric(_ code: String, label: String) -> PendingInteractionMetric {
        return PendingInteractionMetric(
            code: code,
            label: label,
            expiresAt: 0,
            encounterID: "",
            checksum: "",
            archived: false,
            pinned: false,
            status: PendingInteractionMetricStatus.draft
        )
    }
}
