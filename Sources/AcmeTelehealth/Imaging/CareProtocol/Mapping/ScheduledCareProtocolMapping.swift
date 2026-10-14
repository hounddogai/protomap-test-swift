import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled care protocol mapping is in its life cycle.
    enum ScheduledCareProtocolMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One scheduled care protocol mapping, with what the planners need to act on it.
    final class ScheduledCareProtocolMapping {
        var code: String
        var label: String
        var unit: String
        var name: String
        var rate: Double
        var facility: String
        var status: ScheduledCareProtocolMappingStatus

        init(code: String, label: String, unit: String, name: String, rate: Double, facility: String, status: ScheduledCareProtocolMappingStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.name = name
            self.rate = rate
            self.facility = facility
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

        func canMoveTo(_ next: ScheduledCareProtocolMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledCareProtocolMappingStatus.stopped
            case .warming:
                return next == ScheduledCareProtocolMappingStatus.draining
            case .ready:
                return next == ScheduledCareProtocolMappingStatus.stopped
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

        func moveTo(_ next: ScheduledCareProtocolMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> ScheduledCareProtocolMapping {
            return ScheduledCareProtocolMapping(
                code: code,
                label: label,
                unit: unit,
                name: name,
                rate: rate,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled care protocol mapping in status idle.
    static func newScheduledCareProtocolMapping(_ code: String, label: String) -> ScheduledCareProtocolMapping {
        return ScheduledCareProtocolMapping(
            code: code,
            label: label,
            unit: "",
            name: "",
            rate: 0.0,
            facility: "",
            status: ScheduledCareProtocolMappingStatus.idle
        )
    }
}
