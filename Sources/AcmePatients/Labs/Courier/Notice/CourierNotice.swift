import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier notice is in its life cycle.
    enum CourierNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A courier notice. Its code is unique within a tenant.
    final class CourierNotice {
        var code: String
        var name: String
        var encounterID: String
        var phone: String
        var unit: String
        var amount: Double
        var status: CourierNoticeStatus

        init(code: String, name: String, encounterID: String, phone: String, unit: String, amount: Double, status: CourierNoticeStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.phone = phone
            self.unit = unit
            self.amount = amount
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

        func canMoveTo(_ next: CourierNoticeStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CourierNoticeStatus.draining
            case .draining:
                return next == CourierNoticeStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> CourierNotice {
            return CourierNotice(
                code: code,
                name: name,
                encounterID: encounterID,
                phone: phone,
                unit: unit,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a courier notice in status idle.
    static func newCourierNotice(_ code: String, name: String) -> CourierNotice {
        return CourierNotice(
            code: code,
            name: name,
            encounterID: "",
            phone: "",
            unit: "",
            amount: 0.0,
            status: CourierNoticeStatus.idle
        )
    }
}
