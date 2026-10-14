import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict program manifest is in its life cycle.
    enum StrictProgramManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a strict program manifest and its current status.
    final class StrictProgramManifest {
        var code: String
        var label: String
        var unit: String
        var startsAt: Int
        var ownerID: String
        var minimum: Double
        var allergy: String
        var durationMinutes: Int
        var budget: Double
        var status: StrictProgramManifestStatus

        init(code: String, label: String, unit: String, startsAt: Int, ownerID: String, minimum: Double, allergy: String, durationMinutes: Int, budget: Double, status: StrictProgramManifestStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.startsAt = startsAt
            self.ownerID = ownerID
            self.minimum = minimum
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.budget = budget
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

        func canMoveTo(_ next: StrictProgramManifestStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictProgramManifestStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == StrictProgramManifestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictProgramManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict program manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveValue() -> Double {
            return ((Double(startsAt) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictProgramManifest {
            return StrictProgramManifest(
                code: code,
                label: label,
                unit: unit,
                startsAt: startsAt,
                ownerID: ownerID,
                minimum: minimum,
                allergy: allergy,
                durationMinutes: durationMinutes,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict program manifest in status planned.
    static func newStrictProgramManifest(_ code: String, label: String) -> StrictProgramManifest {
        return StrictProgramManifest(
            code: code,
            label: label,
            unit: "",
            startsAt: 0,
            ownerID: "",
            minimum: 0.0,
            allergy: "",
            durationMinutes: 0,
            budget: 0.0,
            status: StrictProgramManifestStatus.planned
        )
    }
}
