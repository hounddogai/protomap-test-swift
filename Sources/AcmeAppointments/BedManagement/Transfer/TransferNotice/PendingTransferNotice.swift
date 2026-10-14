import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending transfer notice is in its life cycle.
    enum PendingTransferNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending transfer notice as the transfer team keeps it.
    final class PendingTransferNotice {
        var code: String
        var label: String
        var budget: Double
        var threshold: Double
        var tags: [String]
        var dosageMg: Double
        var margin: Double
        var minimum: Double
        var status: PendingTransferNoticeStatus

        init(code: String, label: String, budget: Double, threshold: Double, tags: [String], dosageMg: Double, margin: Double, minimum: Double, status: PendingTransferNoticeStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.threshold = threshold
            self.tags = tags
            self.dosageMg = dosageMg
            self.margin = margin
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingTransferNoticeStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingTransferNoticeStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingTransferNoticeStatus.completed || next == PendingTransferNoticeStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingTransferNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending transfer notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return (budget * minimum * 100).rounded() / 100
        }

        func copyValue() -> PendingTransferNotice {
            return PendingTransferNotice(
                code: code,
                label: label,
                budget: budget,
                threshold: threshold,
                tags: tags,
                dosageMg: dosageMg,
                margin: margin,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending transfer notice in status planned.
    static func newPendingTransferNotice(_ code: String, label: String) -> PendingTransferNotice {
        return PendingTransferNotice(
            code: code,
            label: label,
            budget: 0.0,
            threshold: 0.0,
            tags: [],
            dosageMg: 0.0,
            margin: 0.0,
            minimum: 0.0,
            status: PendingTransferNoticeStatus.planned
        )
    }
}
