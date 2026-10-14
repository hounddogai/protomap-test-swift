import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered isolation target is in its life cycle.
    enum TieredIsolationTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered isolation target as the isolation team keeps it.
    final class TieredIsolationTarget {
        var code: String
        var name: String
        var specialty: String
        var acuity: Int
        var diagnosisCode: String
        var unit: String
        var priority: Int
        var quantity: Int
        var status: TieredIsolationTargetStatus

        init(code: String, name: String, specialty: String, acuity: Int, diagnosisCode: String, unit: String, priority: Int, quantity: Int, status: TieredIsolationTargetStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.unit = unit
            self.priority = priority
            self.quantity = quantity
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

        func canMoveTo(_ next: TieredIsolationTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredIsolationTargetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredIsolationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered isolation target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return (Double(priority) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> TieredIsolationTarget {
            return TieredIsolationTarget(
                code: code,
                name: name,
                specialty: specialty,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                unit: unit,
                priority: priority,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered isolation target in status proposed.
    static func newTieredIsolationTarget(_ code: String, name: String) -> TieredIsolationTarget {
        return TieredIsolationTarget(
            code: code,
            name: name,
            specialty: "",
            acuity: 0,
            diagnosisCode: "",
            unit: "",
            priority: 0,
            quantity: 0,
            status: TieredIsolationTargetStatus.proposed
        )
    }
}
