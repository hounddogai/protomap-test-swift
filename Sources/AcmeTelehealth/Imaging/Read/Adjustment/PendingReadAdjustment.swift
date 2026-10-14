import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending read adjustment is in its life cycle.
    enum PendingReadAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a pending read adjustment and its current status.
    final class PendingReadAdjustment {
        var code: String
        var title: String
        var channel: String
        var quantity: Int
        var region: String
        var createdAt: Int
        var score: Double
        var retries: Int
        var endsAt: Int
        var notes: String
        var approved: Bool
        var status: PendingReadAdjustmentStatus

        init(code: String, title: String, channel: String, quantity: Int, region: String, createdAt: Int, score: Double, retries: Int, endsAt: Int, notes: String, approved: Bool, status: PendingReadAdjustmentStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.quantity = quantity
            self.region = region
            self.createdAt = createdAt
            self.score = score
            self.retries = retries
            self.endsAt = endsAt
            self.notes = notes
            self.approved = approved
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

        func canMoveTo(_ next: PendingReadAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
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
                return next == PendingReadAdjustmentStatus.done
            case .done:
                return next == PendingReadAdjustmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingReadAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending read adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return (Double(quantity) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> PendingReadAdjustment {
            return PendingReadAdjustment(
                code: code,
                title: title,
                channel: channel,
                quantity: quantity,
                region: region,
                createdAt: createdAt,
                score: score,
                retries: retries,
                endsAt: endsAt,
                notes: notes,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending read adjustment in status new.
    static func newPendingReadAdjustment(_ code: String, title: String) -> PendingReadAdjustment {
        return PendingReadAdjustment(
            code: code,
            title: title,
            channel: "",
            quantity: 0,
            region: "",
            createdAt: 0,
            score: 0.0,
            retries: 0,
            endsAt: 0,
            notes: "",
            approved: false,
            status: PendingReadAdjustmentStatus.new
        )
    }
}
