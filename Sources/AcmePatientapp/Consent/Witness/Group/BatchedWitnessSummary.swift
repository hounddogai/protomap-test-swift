import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched witness summary is in its life cycle.
    enum BatchedWitnessSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One batched witness summary, with what the planners need to act on it.
    final class BatchedWitnessSummary {
        var code: String
        var title: String
        var updatedAt: Int
        var region: String
        var channel: String
        var allergy: String
        var contactEmail: String
        var priority: Int
        var status: BatchedWitnessSummaryStatus

        init(code: String, title: String, updatedAt: Int, region: String, channel: String, allergy: String, contactEmail: String, priority: Int, status: BatchedWitnessSummaryStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.region = region
            self.channel = channel
            self.allergy = allergy
            self.contactEmail = contactEmail
            self.priority = priority
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

        func canMoveTo(_ next: BatchedWitnessSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == BatchedWitnessSummaryStatus.done || next == BatchedWitnessSummaryStatus.failed
            case .done:
                return next == BatchedWitnessSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedWitnessSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched witness summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(updatedAt) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedWitnessSummary {
            return BatchedWitnessSummary(
                code: code,
                title: title,
                updatedAt: updatedAt,
                region: region,
                channel: channel,
                allergy: allergy,
                contactEmail: contactEmail,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a batched witness summary in status new.
    static func newBatchedWitnessSummary(_ code: String, title: String) -> BatchedWitnessSummary {
        return BatchedWitnessSummary(
            code: code,
            title: title,
            updatedAt: 0,
            region: "",
            channel: "",
            allergy: "",
            contactEmail: "",
            priority: 0,
            status: BatchedWitnessSummaryStatus.new
        )
    }
}
