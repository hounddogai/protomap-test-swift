import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert notice is in its life cycle.
    enum AlertNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A alert notice. Its code is unique within a tenant.
    final class AlertNotice {
        var code: String
        var name: String
        var refills: Int
        var weight: Double
        var windowDays: Int
        var region: String
        var channel: String
        var graceDays: Int
        var sequence: Int
        var cost: Double
        var status: AlertNoticeStatus

        init(code: String, name: String, refills: Int, weight: Double, windowDays: Int, region: String, channel: String, graceDays: Int, sequence: Int, cost: Double, status: AlertNoticeStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.weight = weight
            self.windowDays = windowDays
            self.region = region
            self.channel = channel
            self.graceDays = graceDays
            self.sequence = sequence
            self.cost = cost
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

        func canMoveTo(_ next: AlertNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AlertNoticeStatus.resolved
            case .resolved:
                return next == AlertNoticeStatus.reopened || next == AlertNoticeStatus.archived
            case .reopened:
                return next == AlertNoticeStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("alert notice") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(graceDays) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> AlertNotice {
            return AlertNotice(
                code: code,
                name: name,
                refills: refills,
                weight: weight,
                windowDays: windowDays,
                region: region,
                channel: channel,
                graceDays: graceDays,
                sequence: sequence,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a alert notice in status open.
    static func newAlertNotice(_ code: String, name: String) -> AlertNotice {
        return AlertNotice(
            code: code,
            name: name,
            refills: 0,
            weight: 0.0,
            windowDays: 0,
            region: "",
            channel: "",
            graceDays: 0,
            sequence: 0,
            cost: 0.0,
            status: AlertNoticeStatus.`open`
        )
    }
}
