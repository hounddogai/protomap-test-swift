import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall template is in its life cycle.
    enum PendingRecallTemplateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A pending recall template. Its code is unique within a tenant.
    final class PendingRecallTemplate {
        var code: String
        var title: String
        var cost: Double
        var channel: String
        var ceiling: Double
        var threshold: Double
        var status: PendingRecallTemplateStatus

        init(code: String, title: String, cost: Double, channel: String, ceiling: Double, threshold: Double, status: PendingRecallTemplateStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.channel = channel
            self.ceiling = ceiling
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingRecallTemplateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PendingRecallTemplateStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRecallTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return ((ceiling - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingRecallTemplate {
            return PendingRecallTemplate(
                code: code,
                title: title,
                cost: cost,
                channel: channel,
                ceiling: ceiling,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending recall template in status created.
    static func newPendingRecallTemplate(_ code: String, title: String) -> PendingRecallTemplate {
        return PendingRecallTemplate(
            code: code,
            title: title,
            cost: 0.0,
            channel: "",
            ceiling: 0.0,
            threshold: 0.0,
            status: PendingRecallTemplateStatus.created
        )
    }
}
