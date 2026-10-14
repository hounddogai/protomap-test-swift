import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan override is in its life cycle.
    enum AcuityPlanOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A acuity plan override. Its code is unique within a tenant.
    final class AcuityPlanOverride {
        var code: String
        var title: String
        var priority: Int
        var region: String
        var payer: String
        var channel: String
        var checksum: String
        var score: Double
        var active: Bool
        var status: AcuityPlanOverrideStatus

        init(code: String, title: String, priority: Int, region: String, payer: String, channel: String, checksum: String, score: Double, active: Bool, status: AcuityPlanOverrideStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.region = region
            self.payer = payer
            self.channel = channel
            self.checksum = checksum
            self.score = score
            self.active = active
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

        func canMoveTo(_ next: AcuityPlanOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AcuityPlanOverrideStatus.archived
            case .resolved:
                return next == AcuityPlanOverrideStatus.reopened
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

        func moveTo(_ next: AcuityPlanOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("acuity plan override") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(priority) - score) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanOverride {
            return AcuityPlanOverride(
                code: code,
                title: title,
                priority: priority,
                region: region,
                payer: payer,
                channel: channel,
                checksum: checksum,
                score: score,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a acuity plan override in status open.
    static func newAcuityPlanOverride(_ code: String, title: String) -> AcuityPlanOverride {
        return AcuityPlanOverride(
            code: code,
            title: title,
            priority: 0,
            region: "",
            payer: "",
            channel: "",
            checksum: "",
            score: 0.0,
            active: false,
            status: AcuityPlanOverrideStatus.`open`
        )
    }
}
