import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched transfer claim is in its life cycle.
    enum BatchedTransferClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched transfer claim as the transfer team keeps it.
    final class BatchedTransferClaim {
        var code: String
        var name: String
        var weight: Double
        var durationMinutes: Int
        var specialty: String
        var region: String
        var endsAt: Int
        var channel: String
        var retries: Int
        var approved: Bool
        var priority: Int
        var status: BatchedTransferClaimStatus

        init(code: String, name: String, weight: Double, durationMinutes: Int, specialty: String, region: String, endsAt: Int, channel: String, retries: Int, approved: Bool, priority: Int, status: BatchedTransferClaimStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.durationMinutes = durationMinutes
            self.specialty = specialty
            self.region = region
            self.endsAt = endsAt
            self.channel = channel
            self.retries = retries
            self.approved = approved
            self.priority = priority
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

        func canMoveTo(_ next: BatchedTransferClaimStatus) -> Bool {
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
                return next == BatchedTransferClaimStatus.reopened
            case .resolved:
                return next == BatchedTransferClaimStatus.reopened || next == BatchedTransferClaimStatus.archived
            case .reopened:
                return next == BatchedTransferClaimStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedTransferClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched transfer claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return (Double(endsAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> BatchedTransferClaim {
            return BatchedTransferClaim(
                code: code,
                name: name,
                weight: weight,
                durationMinutes: durationMinutes,
                specialty: specialty,
                region: region,
                endsAt: endsAt,
                channel: channel,
                retries: retries,
                approved: approved,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a batched transfer claim in status open.
    static func newBatchedTransferClaim(_ code: String, name: String) -> BatchedTransferClaim {
        return BatchedTransferClaim(
            code: code,
            name: name,
            weight: 0.0,
            durationMinutes: 0,
            specialty: "",
            region: "",
            endsAt: 0,
            channel: "",
            retries: 0,
            approved: false,
            priority: 0,
            status: BatchedTransferClaimStatus.`open`
        )
    }
}
