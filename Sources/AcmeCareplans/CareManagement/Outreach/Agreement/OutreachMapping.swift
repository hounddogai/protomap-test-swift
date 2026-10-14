import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach mapping is in its life cycle.
    enum OutreachMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a outreach mapping and its current status.
    final class OutreachMapping {
        var code: String
        var title: String
        var specialty: String
        var phone: String
        var channel: String
        var facility: String
        var amount: Double
        var status: OutreachMappingStatus

        init(code: String, title: String, specialty: String, phone: String, channel: String, facility: String, amount: Double, status: OutreachMappingStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.phone = phone
            self.channel = channel
            self.facility = facility
            self.amount = amount
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

        func canMoveTo(_ next: OutreachMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == OutreachMappingStatus.inProgress || next == OutreachMappingStatus.cancelled
            case .scheduled:
                return next == OutreachMappingStatus.inProgress || next == OutreachMappingStatus.cancelled
            case .inProgress:
                return next == OutreachMappingStatus.completed || next == OutreachMappingStatus.cancelled
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

        func moveTo(_ next: OutreachMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> OutreachMapping {
            return OutreachMapping(
                code: code,
                title: title,
                specialty: specialty,
                phone: phone,
                channel: channel,
                facility: facility,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a outreach mapping in status planned.
    static func newOutreachMapping(_ code: String, title: String) -> OutreachMapping {
        return OutreachMapping(
            code: code,
            title: title,
            specialty: "",
            phone: "",
            channel: "",
            facility: "",
            amount: 0.0,
            status: OutreachMappingStatus.planned
        )
    }
}
