import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global network score is in its life cycle.
    enum GlobalNetworkScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global network score, with what the planners need to act on it.
    final class GlobalNetworkScore {
        var code: String
        var label: String
        var refills: Int
        var unit: String
        var version: Int
        var channel: String
        var encounterID: String
        var budget: Double
        var status: GlobalNetworkScoreStatus

        init(code: String, label: String, refills: Int, unit: String, version: Int, channel: String, encounterID: String, budget: Double, status: GlobalNetworkScoreStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.unit = unit
            self.version = version
            self.channel = channel
            self.encounterID = encounterID
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalNetworkScoreStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalNetworkScoreStatus.warming
            case .warming:
                return next == GlobalNetworkScoreStatus.ready || next == GlobalNetworkScoreStatus.draining
            case .ready:
                return next == GlobalNetworkScoreStatus.draining || next == GlobalNetworkScoreStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalNetworkScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global network score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("global network score") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(version) + budget) * 100).rounded() / 100
        }

        func copyValue() -> GlobalNetworkScore {
            return GlobalNetworkScore(
                code: code,
                label: label,
                refills: refills,
                unit: unit,
                version: version,
                channel: channel,
                encounterID: encounterID,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global network score in status idle.
    static func newGlobalNetworkScore(_ code: String, label: String) -> GlobalNetworkScore {
        return GlobalNetworkScore(
            code: code,
            label: label,
            refills: 0,
            unit: "",
            version: 0,
            channel: "",
            encounterID: "",
            budget: 0.0,
            status: GlobalNetworkScoreStatus.idle
        )
    }
}
