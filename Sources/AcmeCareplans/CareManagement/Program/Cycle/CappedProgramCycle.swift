import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped program cycle is in its life cycle.
    enum CappedProgramCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped program cycle. Its code is unique within a tenant.
    final class CappedProgramCycle {
        var code: String
        var label: String
        var threshold: Double
        var phone: String
        var attempts: Int
        var version: Int
        var allergy: String
        var unit: String
        var priority: Int
        var patientRef: String
        var status: CappedProgramCycleStatus

        init(code: String, label: String, threshold: Double, phone: String, attempts: Int, version: Int, allergy: String, unit: String, priority: Int, patientRef: String, status: CappedProgramCycleStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.phone = phone
            self.attempts = attempts
            self.version = version
            self.allergy = allergy
            self.unit = unit
            self.priority = priority
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

        func canMoveTo(_ next: CappedProgramCycleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: CappedProgramCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped program cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(version) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> CappedProgramCycle {
            return CappedProgramCycle(
                code: code,
                label: label,
                threshold: threshold,
                phone: phone,
                attempts: attempts,
                version: version,
                allergy: allergy,
                unit: unit,
                priority: priority,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped program cycle in status requested.
    static func newCappedProgramCycle(_ code: String, label: String) -> CappedProgramCycle {
        return CappedProgramCycle(
            code: code,
            label: label,
            threshold: 0.0,
            phone: "",
            attempts: 0,
            version: 0,
            allergy: "",
            unit: "",
            priority: 0,
            patientRef: "",
            status: CappedProgramCycleStatus.requested
        )
    }
}
