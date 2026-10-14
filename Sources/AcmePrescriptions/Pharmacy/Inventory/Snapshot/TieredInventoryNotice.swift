import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered inventory notice is in its life cycle.
    enum TieredInventoryNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One tiered inventory notice, with what the planners need to act on it.
    final class TieredInventoryNotice {
        var code: String
        var name: String
        var diagnosisCode: String
        var unit: String
        var weight: Double
        var status: TieredInventoryNoticeStatus

        init(code: String, name: String, diagnosisCode: String, unit: String, weight: Double, status: TieredInventoryNoticeStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.unit = unit
            self.weight = weight
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

        func canMoveTo(_ next: TieredInventoryNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredInventoryNoticeStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredInventoryNoticeStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredInventoryNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered inventory notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered inventory notice") \(code)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> TieredInventoryNotice {
            return TieredInventoryNotice(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                unit: unit,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered inventory notice in status proposed.
    static func newTieredInventoryNotice(_ code: String, name: String) -> TieredInventoryNotice {
        return TieredInventoryNotice(
            code: code,
            name: name,
            diagnosisCode: "",
            unit: "",
            weight: 0.0,
            status: TieredInventoryNoticeStatus.proposed
        )
    }
}
