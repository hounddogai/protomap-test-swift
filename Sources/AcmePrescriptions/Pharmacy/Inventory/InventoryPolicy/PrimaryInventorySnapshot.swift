import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary inventory snapshot is in its life cycle.
    enum PrimaryInventorySnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary inventory snapshot as the inventory team keeps it.
    final class PrimaryInventorySnapshot {
        var code: String
        var label: String
        var discount: Double
        var revision: Int
        var createdAt: Int
        var ceiling: Double
        var archived: Bool
        var status: PrimaryInventorySnapshotStatus

        init(code: String, label: String, discount: Double, revision: Int, createdAt: Int, ceiling: Double, archived: Bool, status: PrimaryInventorySnapshotStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.revision = revision
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryInventorySnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryInventorySnapshotStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryInventorySnapshotStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryInventorySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary inventory snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return ((Double(revision) - discount) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryInventorySnapshot {
            return PrimaryInventorySnapshot(
                code: code,
                label: label,
                discount: discount,
                revision: revision,
                createdAt: createdAt,
                ceiling: ceiling,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary inventory snapshot in status open.
    static func newPrimaryInventorySnapshot(_ code: String, label: String) -> PrimaryInventorySnapshot {
        return PrimaryInventorySnapshot(
            code: code,
            label: label,
            discount: 0.0,
            revision: 0,
            createdAt: 0,
            ceiling: 0.0,
            archived: false,
            status: PrimaryInventorySnapshotStatus.`open`
        )
    }
}
