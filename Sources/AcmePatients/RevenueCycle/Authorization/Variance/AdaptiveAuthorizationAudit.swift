import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive authorization audit is in its life cycle.
    enum AdaptiveAuthorizationAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive authorization audit. Its code is unique within a tenant.
    final class AdaptiveAuthorizationAudit {
        var code: String
        var title: String
        var payer: String
        var source: String
        var capacity: Int
        var sequence: Int
        var startsAt: Int
        var status: AdaptiveAuthorizationAuditStatus

        init(code: String, title: String, payer: String, source: String, capacity: Int, sequence: Int, startsAt: Int, status: AdaptiveAuthorizationAuditStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.source = source
            self.capacity = capacity
            self.sequence = sequence
            self.startsAt = startsAt
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

        func canMoveTo(_ next: AdaptiveAuthorizationAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveAuthorizationAuditStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AdaptiveAuthorizationAuditStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveAuthorizationAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive authorization audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive authorization audit") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(capacity) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAuthorizationAudit {
            return AdaptiveAuthorizationAudit(
                code: code,
                title: title,
                payer: payer,
                source: source,
                capacity: capacity,
                sequence: sequence,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a adaptive authorization audit in status created.
    static func newAdaptiveAuthorizationAudit(_ code: String, title: String) -> AdaptiveAuthorizationAudit {
        return AdaptiveAuthorizationAudit(
            code: code,
            title: title,
            payer: "",
            source: "",
            capacity: 0,
            sequence: 0,
            startsAt: 0,
            status: AdaptiveAuthorizationAuditStatus.created
        )
    }
}
