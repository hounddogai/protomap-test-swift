import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled proxy notice is in its life cycle.
    enum ScheduledProxyNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One scheduled proxy notice, with what the planners need to act on it.
    final class ScheduledProxyNotice {
        var code: String
        var title: String
        var copay: Double
        var margin: Double
        var budget: Double
        var acuity: Int
        var batchSize: Int
        var endsAt: Int
        var threshold: Double
        var externalRef: String
        var status: ScheduledProxyNoticeStatus

        init(code: String, title: String, copay: Double, margin: Double, budget: Double, acuity: Int, batchSize: Int, endsAt: Int, threshold: Double, externalRef: String, status: ScheduledProxyNoticeStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.margin = margin
            self.budget = budget
            self.acuity = acuity
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.threshold = threshold
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledProxyNoticeStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledProxyNoticeStatus.inProgress
            case .scheduled:
                return next == ScheduledProxyNoticeStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ScheduledProxyNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled proxy notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return ((budget + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledProxyNotice {
            return ScheduledProxyNotice(
                code: code,
                title: title,
                copay: copay,
                margin: margin,
                budget: budget,
                acuity: acuity,
                batchSize: batchSize,
                endsAt: endsAt,
                threshold: threshold,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled proxy notice in status planned.
    static func newScheduledProxyNotice(_ code: String, title: String) -> ScheduledProxyNotice {
        return ScheduledProxyNotice(
            code: code,
            title: title,
            copay: 0.0,
            margin: 0.0,
            budget: 0.0,
            acuity: 0,
            batchSize: 0,
            endsAt: 0,
            threshold: 0.0,
            externalRef: "",
            status: ScheduledProxyNoticeStatus.planned
        )
    }
}
