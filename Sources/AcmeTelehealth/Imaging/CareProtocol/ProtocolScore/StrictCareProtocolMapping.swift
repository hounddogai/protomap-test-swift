import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict care protocol mapping is in its life cycle.
    enum StrictCareProtocolMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A strict care protocol mapping as the care protocol team keeps it.
    final class StrictCareProtocolMapping {
        var code: String
        var title: String
        var budget: Double
        var ward: String
        var name: String
        var approved: Bool
        var channel: String
        var status: StrictCareProtocolMappingStatus

        init(code: String, title: String, budget: Double, ward: String, name: String, approved: Bool, channel: String, status: StrictCareProtocolMappingStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.ward = ward
            self.name = name
            self.approved = approved
            self.channel = channel
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

        func canMoveTo(_ next: StrictCareProtocolMappingStatus) -> Bool {
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
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StrictCareProtocolMappingStatus.draining
            case .draining:
                return next == StrictCareProtocolMappingStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictCareProtocolMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict care protocol mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> StrictCareProtocolMapping {
            return StrictCareProtocolMapping(
                code: code,
                title: title,
                budget: budget,
                ward: ward,
                name: name,
                approved: approved,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict care protocol mapping in status idle.
    static func newStrictCareProtocolMapping(_ code: String, title: String) -> StrictCareProtocolMapping {
        return StrictCareProtocolMapping(
            code: code,
            title: title,
            budget: 0.0,
            ward: "",
            name: "",
            approved: false,
            channel: "",
            status: StrictCareProtocolMappingStatus.idle
        )
    }
}
