import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial record is in its life cycle.
    enum DenialRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A denial record. Its code is unique within a tenant.
    final class DenialRecord {
        var code: String
        var name: String
        var windowDays: Int
        var amount: Double
        var label: String
        var ratio: Double
        var minimum: Double
        var ward: String
        var facility: String
        var floorValue: Double
        var status: DenialRecordStatus

        init(code: String, name: String, windowDays: Int, amount: Double, label: String, ratio: Double, minimum: Double, ward: String, facility: String, floorValue: Double, status: DenialRecordStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.amount = amount
            self.label = label
            self.ratio = ratio
            self.minimum = minimum
            self.ward = ward
            self.facility = facility
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DenialRecordStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DenialRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return ((minimum - ratio) * 100).rounded() / 100
        }

        func copyValue() -> DenialRecord {
            return DenialRecord(
                code: code,
                name: name,
                windowDays: windowDays,
                amount: amount,
                label: label,
                ratio: ratio,
                minimum: minimum,
                ward: ward,
                facility: facility,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a denial record in status proposed.
    static func newDenialRecord(_ code: String, name: String) -> DenialRecord {
        return DenialRecord(
            code: code,
            name: name,
            windowDays: 0,
            amount: 0.0,
            label: "",
            ratio: 0.0,
            minimum: 0.0,
            ward: "",
            facility: "",
            floorValue: 0.0,
            status: DenialRecordStatus.proposed
        )
    }
}
