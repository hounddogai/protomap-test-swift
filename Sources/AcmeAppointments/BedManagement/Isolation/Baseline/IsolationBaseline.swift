import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation baseline is in its life cycle.
    enum IsolationBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A isolation baseline as the isolation team keeps it.
    final class IsolationBaseline {
        var code: String
        var label: String
        var timezone: String
        var windowDays: Int
        var facility: String
        var approved: Bool
        var floorValue: Double
        var rate: Double
        var channel: String
        var status: IsolationBaselineStatus

        init(code: String, label: String, timezone: String, windowDays: Int, facility: String, approved: Bool, floorValue: Double, rate: Double, channel: String, status: IsolationBaselineStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.windowDays = windowDays
            self.facility = facility
            self.approved = approved
            self.floorValue = floorValue
            self.rate = rate
            self.channel = channel
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

        func canMoveTo(_ next: IsolationBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == IsolationBaselineStatus.retired
            case .published:
                return next == IsolationBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netVolume() -> Double {
            return ((rate - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> IsolationBaseline {
            return IsolationBaseline(
                code: code,
                label: label,
                timezone: timezone,
                windowDays: windowDays,
                facility: facility,
                approved: approved,
                floorValue: floorValue,
                rate: rate,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a isolation baseline in status created.
    static func newIsolationBaseline(_ code: String, label: String) -> IsolationBaseline {
        return IsolationBaseline(
            code: code,
            label: label,
            timezone: "",
            windowDays: 0,
            facility: "",
            approved: false,
            floorValue: 0.0,
            rate: 0.0,
            channel: "",
            status: IsolationBaselineStatus.created
        )
    }
}
