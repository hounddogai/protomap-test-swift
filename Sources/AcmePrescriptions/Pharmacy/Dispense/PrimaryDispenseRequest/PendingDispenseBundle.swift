import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending dispense bundle is in its life cycle.
    enum PendingDispenseBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One pending dispense bundle, with what the planners need to act on it.
    final class PendingDispenseBundle {
        var code: String
        var name: String
        var procedureCode: String
        var ownerID: String
        var dosageMg: Double
        var specialty: String
        var priority: Int
        var status: PendingDispenseBundleStatus

        init(code: String, name: String, procedureCode: String, ownerID: String, dosageMg: Double, specialty: String, priority: Int, status: PendingDispenseBundleStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.specialty = specialty
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingDispenseBundleStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingDispenseBundleStatus.revoked || next == PendingDispenseBundleStatus.expired
            case .granted:
                return next == PendingDispenseBundleStatus.revoked || next == PendingDispenseBundleStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PendingDispenseBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending dispense bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return ((dosageMg - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PendingDispenseBundle {
            return PendingDispenseBundle(
                code: code,
                name: name,
                procedureCode: procedureCode,
                ownerID: ownerID,
                dosageMg: dosageMg,
                specialty: specialty,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending dispense bundle in status requested.
    static func newPendingDispenseBundle(_ code: String, name: String) -> PendingDispenseBundle {
        return PendingDispenseBundle(
            code: code,
            name: name,
            procedureCode: "",
            ownerID: "",
            dosageMg: 0.0,
            specialty: "",
            priority: 0,
            status: PendingDispenseBundleStatus.requested
        )
    }
}
