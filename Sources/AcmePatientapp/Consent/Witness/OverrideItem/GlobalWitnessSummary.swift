import AcmePlatform
import Foundation

extension Consent {
    /// Where a global witness summary is in its life cycle.
    enum GlobalWitnessSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a global witness summary and its current status.
    final class GlobalWitnessSummary {
        var code: String
        var title: String
        var channel: String
        var allergy: String
        var visible: Bool
        var externalRef: String
        var timezone: String
        var floorValue: Double
        var status: GlobalWitnessSummaryStatus

        init(code: String, title: String, channel: String, allergy: String, visible: Bool, externalRef: String, timezone: String, floorValue: Double, status: GlobalWitnessSummaryStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.allergy = allergy
            self.visible = visible
            self.externalRef = externalRef
            self.timezone = timezone
            self.floorValue = floorValue
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

        func canMoveTo(_ next: GlobalWitnessSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == GlobalWitnessSummaryStatus.stopped
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

        func moveTo(_ next: GlobalWitnessSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global witness summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> GlobalWitnessSummary {
            return GlobalWitnessSummary(
                code: code,
                title: title,
                channel: channel,
                allergy: allergy,
                visible: visible,
                externalRef: externalRef,
                timezone: timezone,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global witness summary in status idle.
    static func newGlobalWitnessSummary(_ code: String, title: String) -> GlobalWitnessSummary {
        return GlobalWitnessSummary(
            code: code,
            title: title,
            channel: "",
            allergy: "",
            visible: false,
            externalRef: "",
            timezone: "",
            floorValue: 0.0,
            status: GlobalWitnessSummaryStatus.idle
        )
    }
}
