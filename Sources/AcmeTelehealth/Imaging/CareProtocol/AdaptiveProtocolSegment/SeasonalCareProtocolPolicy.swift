import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal care protocol policy is in its life cycle.
    enum SeasonalCareProtocolPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a seasonal care protocol policy and its current status.
    final class SeasonalCareProtocolPolicy {
        var code: String
        var name: String
        var facility: String
        var windowDays: Int
        var region: String
        var status: SeasonalCareProtocolPolicyStatus

        init(code: String, name: String, facility: String, windowDays: Int, region: String, status: SeasonalCareProtocolPolicyStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.windowDays = windowDays
            self.region = region
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

        func canMoveTo(_ next: SeasonalCareProtocolPolicyStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalCareProtocolPolicyStatus.cancelled
            case .scheduled:
                return next == SeasonalCareProtocolPolicyStatus.completed || next == SeasonalCareProtocolPolicyStatus.cancelled
            case .inProgress:
                return next == SeasonalCareProtocolPolicyStatus.completed || next == SeasonalCareProtocolPolicyStatus.cancelled
            case .completed:
                return next == SeasonalCareProtocolPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCareProtocolPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care protocol policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> SeasonalCareProtocolPolicy {
            return SeasonalCareProtocolPolicy(
                code: code,
                name: name,
                facility: facility,
                windowDays: windowDays,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal care protocol policy in status planned.
    static func newSeasonalCareProtocolPolicy(_ code: String, name: String) -> SeasonalCareProtocolPolicy {
        return SeasonalCareProtocolPolicy(
            code: code,
            name: name,
            facility: "",
            windowDays: 0,
            region: "",
            status: SeasonalCareProtocolPolicyStatus.planned
        )
    }
}
