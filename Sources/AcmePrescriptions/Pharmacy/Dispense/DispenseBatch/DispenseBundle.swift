import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense bundle is in its life cycle.
    enum DispenseBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One dispense bundle, with what the planners need to act on it.
    final class DispenseBundle {
        var code: String
        var title: String
        var margin: Double
        var active: Bool
        var floorValue: Double
        var procedureCode: String
        var contactEmail: String
        var durationMinutes: Int
        var priority: Int
        var copay: Double
        var patientRef: String
        var status: DispenseBundleStatus

        init(code: String, title: String, margin: Double, active: Bool, floorValue: Double, procedureCode: String, contactEmail: String, durationMinutes: Int, priority: Int, copay: Double, patientRef: String, status: DispenseBundleStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.active = active
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.copay = copay
            self.patientRef = patientRef
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

        func canMoveTo(_ next: DispenseBundleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DispenseBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netTotal() -> Double {
            return (copay * margin * 100).rounded() / 100
        }

        func copyValue() -> DispenseBundle {
            return DispenseBundle(
                code: code,
                title: title,
                margin: margin,
                active: active,
                floorValue: floorValue,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                durationMinutes: durationMinutes,
                priority: priority,
                copay: copay,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense bundle in status requested.
    static func newDispenseBundle(_ code: String, title: String) -> DispenseBundle {
        return DispenseBundle(
            code: code,
            title: title,
            margin: 0.0,
            active: false,
            floorValue: 0.0,
            procedureCode: "",
            contactEmail: "",
            durationMinutes: 0,
            priority: 0,
            copay: 0.0,
            patientRef: "",
            status: DispenseBundleStatus.requested
        )
    }
}
