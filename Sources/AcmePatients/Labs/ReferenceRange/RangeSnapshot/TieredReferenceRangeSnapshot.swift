import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered reference range snapshot is in its life cycle.
    enum TieredReferenceRangeSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered reference range snapshot, with what the planners need to act on it.
    final class TieredReferenceRangeSnapshot {
        var code: String
        var label: String
        var endsAt: Int
        var amount: Double
        var contactEmail: String
        var status: TieredReferenceRangeSnapshotStatus

        init(code: String, label: String, endsAt: Int, amount: Double, contactEmail: String, status: TieredReferenceRangeSnapshotStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.amount = amount
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: TieredReferenceRangeSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == TieredReferenceRangeSnapshotStatus.resolved || next == TieredReferenceRangeSnapshotStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredReferenceRangeSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered reference range snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("tiered reference range snapshot") \(code)"
        }

        func weightedTotal() -> Double {
            return ((amount + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredReferenceRangeSnapshot {
            return TieredReferenceRangeSnapshot(
                code: code,
                label: label,
                endsAt: endsAt,
                amount: amount,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered reference range snapshot in status open.
    static func newTieredReferenceRangeSnapshot(_ code: String, label: String) -> TieredReferenceRangeSnapshot {
        return TieredReferenceRangeSnapshot(
            code: code,
            label: label,
            endsAt: 0,
            amount: 0.0,
            contactEmail: "",
            status: TieredReferenceRangeSnapshotStatus.`open`
        )
    }
}
