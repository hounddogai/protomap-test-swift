import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback closure snapshot is in its life cycle.
    enum FallbackClosureSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback closure snapshot. Its code is unique within a tenant.
    final class FallbackClosureSnapshot {
        var code: String
        var title: String
        var ceiling: Double
        var ward: String
        var channel: String
        var label: String
        var capacity: Int
        var contactEmail: String
        var discount: Double
        var batchSize: Int
        var status: FallbackClosureSnapshotStatus

        init(code: String, title: String, ceiling: Double, ward: String, channel: String, label: String, capacity: Int, contactEmail: String, discount: Double, batchSize: Int, status: FallbackClosureSnapshotStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.ward = ward
            self.channel = channel
            self.label = label
            self.capacity = capacity
            self.contactEmail = contactEmail
            self.discount = discount
            self.batchSize = batchSize
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

        func canMoveTo(_ next: FallbackClosureSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackClosureSnapshotStatus.resolved || next == FallbackClosureSnapshotStatus.archived
            case .inReview:
                return next == FallbackClosureSnapshotStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == FallbackClosureSnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackClosureSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback closure snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return ((discount + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FallbackClosureSnapshot {
            return FallbackClosureSnapshot(
                code: code,
                title: title,
                ceiling: ceiling,
                ward: ward,
                channel: channel,
                label: label,
                capacity: capacity,
                contactEmail: contactEmail,
                discount: discount,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback closure snapshot in status open.
    static func newFallbackClosureSnapshot(_ code: String, title: String) -> FallbackClosureSnapshot {
        return FallbackClosureSnapshot(
            code: code,
            title: title,
            ceiling: 0.0,
            ward: "",
            channel: "",
            label: "",
            capacity: 0,
            contactEmail: "",
            discount: 0.0,
            batchSize: 0,
            status: FallbackClosureSnapshotStatus.`open`
        )
    }
}
