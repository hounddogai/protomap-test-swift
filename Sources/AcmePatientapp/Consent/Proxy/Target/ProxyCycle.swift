import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy cycle is in its life cycle.
    enum ProxyCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One proxy cycle, with what the planners need to act on it.
    final class ProxyCycle {
        var code: String
        var name: String
        var summary: String
        var floorValue: Double
        var minimum: Double
        var channel: String
        var label: String
        var approved: Bool
        var status: ProxyCycleStatus

        init(code: String, name: String, summary: String, floorValue: Double, minimum: Double, channel: String, label: String, approved: Bool, status: ProxyCycleStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.floorValue = floorValue
            self.minimum = minimum
            self.channel = channel
            self.label = label
            self.approved = approved
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

        func canMoveTo(_ next: ProxyCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProxyCycleStatus.resolved
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ProxyCycleStatus.archived
            case .reopened:
                return next == ProxyCycleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((floorValue - minimum) * 100).rounded() / 100
        }

        func copyValue() -> ProxyCycle {
            return ProxyCycle(
                code: code,
                name: name,
                summary: summary,
                floorValue: floorValue,
                minimum: minimum,
                channel: channel,
                label: label,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a proxy cycle in status open.
    static func newProxyCycle(_ code: String, name: String) -> ProxyCycle {
        return ProxyCycle(
            code: code,
            name: name,
            summary: "",
            floorValue: 0.0,
            minimum: 0.0,
            channel: "",
            label: "",
            approved: false,
            status: ProxyCycleStatus.`open`
        )
    }
}
