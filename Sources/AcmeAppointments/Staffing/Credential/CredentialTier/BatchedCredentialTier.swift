import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched credential tier is in its life cycle.
    enum BatchedCredentialTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched credential tier and its current status.
    final class BatchedCredentialTier {
        var code: String
        var label: String
        var channel: String
        var title: String
        var name: String
        var quantity: Int
        var archived: Bool
        var ratio: Double
        var floorValue: Double
        var segment: String
        var ownerID: String
        var status: BatchedCredentialTierStatus

        init(code: String, label: String, channel: String, title: String, name: String, quantity: Int, archived: Bool, ratio: Double, floorValue: Double, segment: String, ownerID: String, status: BatchedCredentialTierStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.title = title
            self.name = name
            self.quantity = quantity
            self.archived = archived
            self.ratio = ratio
            self.floorValue = floorValue
            self.segment = segment
            self.ownerID = ownerID
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

        func canMoveTo(_ next: BatchedCredentialTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == BatchedCredentialTierStatus.failed
            case .done:
                return next == BatchedCredentialTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCredentialTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched credential tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched credential tier") \(code)"
        }

        func adjustedLoad() -> Double {
            return (ratio * floorValue * 100).rounded() / 100
        }

        func copyValue() -> BatchedCredentialTier {
            return BatchedCredentialTier(
                code: code,
                label: label,
                channel: channel,
                title: title,
                name: name,
                quantity: quantity,
                archived: archived,
                ratio: ratio,
                floorValue: floorValue,
                segment: segment,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched credential tier in status new.
    static func newBatchedCredentialTier(_ code: String, label: String) -> BatchedCredentialTier {
        return BatchedCredentialTier(
            code: code,
            label: label,
            channel: "",
            title: "",
            name: "",
            quantity: 0,
            archived: false,
            ratio: 0.0,
            floorValue: 0.0,
            segment: "",
            ownerID: "",
            status: BatchedCredentialTierStatus.new
        )
    }
}
