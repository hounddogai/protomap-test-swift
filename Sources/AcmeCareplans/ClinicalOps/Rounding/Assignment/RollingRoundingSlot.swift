import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling rounding slot is in its life cycle.
    enum RollingRoundingSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling rounding slot, with what the planners need to act on it.
    final class RollingRoundingSlot {
        var code: String
        var label: String
        var rate: Double
        var diagnosisCode: String
        var timezone: String
        var encounterID: String
        var budget: Double
        var specialty: String
        var expiresAt: Int
        var graceDays: Int
        var allergy: String
        var status: RollingRoundingSlotStatus

        init(code: String, label: String, rate: Double, diagnosisCode: String, timezone: String, encounterID: String, budget: Double, specialty: String, expiresAt: Int, graceDays: Int, allergy: String, status: RollingRoundingSlotStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.encounterID = encounterID
            self.budget = budget
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.graceDays = graceDays
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingRoundingSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingRoundingSlotStatus.running || next == RollingRoundingSlotStatus.done
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingRoundingSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling rounding slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((Double(expiresAt) - rate) * 100).rounded() / 100
        }

        func copyValue() -> RollingRoundingSlot {
            return RollingRoundingSlot(
                code: code,
                label: label,
                rate: rate,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                encounterID: encounterID,
                budget: budget,
                specialty: specialty,
                expiresAt: expiresAt,
                graceDays: graceDays,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling rounding slot in status new.
    static func newRollingRoundingSlot(_ code: String, label: String) -> RollingRoundingSlot {
        return RollingRoundingSlot(
            code: code,
            label: label,
            rate: 0.0,
            diagnosisCode: "",
            timezone: "",
            encounterID: "",
            budget: 0.0,
            specialty: "",
            expiresAt: 0,
            graceDays: 0,
            allergy: "",
            status: RollingRoundingSlotStatus.new
        )
    }
}
