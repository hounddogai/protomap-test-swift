import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual inventory snapshot is in its life cycle.
    enum ManualInventorySnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One manual inventory snapshot, with what the planners need to act on it.
    final class ManualInventorySnapshot {
        var code: String
        var label: String
        var channel: String
        var contactEmail: String
        var endsAt: Int
        var score: Double
        var maximum: Double
        var notes: String
        var quantity: Int
        var status: ManualInventorySnapshotStatus

        init(code: String, label: String, channel: String, contactEmail: String, endsAt: Int, score: Double, maximum: Double, notes: String, quantity: Int, status: ManualInventorySnapshotStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.contactEmail = contactEmail
            self.endsAt = endsAt
            self.score = score
            self.maximum = maximum
            self.notes = notes
            self.quantity = quantity
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

        func canMoveTo(_ next: ManualInventorySnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualInventorySnapshotStatus.inReview || next == ManualInventorySnapshotStatus.resolved
            case .inReview:
                return next == ManualInventorySnapshotStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ManualInventorySnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualInventorySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual inventory snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("manual inventory snapshot") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(quantity) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ManualInventorySnapshot {
            return ManualInventorySnapshot(
                code: code,
                label: label,
                channel: channel,
                contactEmail: contactEmail,
                endsAt: endsAt,
                score: score,
                maximum: maximum,
                notes: notes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual inventory snapshot in status open.
    static func newManualInventorySnapshot(_ code: String, label: String) -> ManualInventorySnapshot {
        return ManualInventorySnapshot(
            code: code,
            label: label,
            channel: "",
            contactEmail: "",
            endsAt: 0,
            score: 0.0,
            maximum: 0.0,
            notes: "",
            quantity: 0,
            status: ManualInventorySnapshotStatus.`open`
        )
    }
}
