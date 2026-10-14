import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default network record is in its life cycle.
    enum DefaultNetworkRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default network record and its current status.
    final class DefaultNetworkRecord {
        var code: String
        var title: String
        var channel: String
        var ward: String
        var unit: String
        var specialty: String
        var amount: Double
        var status: DefaultNetworkRecordStatus

        init(code: String, title: String, channel: String, ward: String, unit: String, specialty: String, amount: Double, status: DefaultNetworkRecordStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.ward = ward
            self.unit = unit
            self.specialty = specialty
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

        func canMoveTo(_ next: DefaultNetworkRecordStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DefaultNetworkRecordStatus.completed || next == DefaultNetworkRecordStatus.cancelled
            case .completed:
                return next == DefaultNetworkRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultNetworkRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default network record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> DefaultNetworkRecord {
            return DefaultNetworkRecord(
                code: code,
                title: title,
                channel: channel,
                ward: ward,
                unit: unit,
                specialty: specialty,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default network record in status planned.
    static func newDefaultNetworkRecord(_ code: String, title: String) -> DefaultNetworkRecord {
        return DefaultNetworkRecord(
            code: code,
            title: title,
            channel: "",
            ward: "",
            unit: "",
            specialty: "",
            amount: 0.0,
            status: DefaultNetworkRecordStatus.planned
        )
    }
}
