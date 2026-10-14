import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict task preference is in its life cycle.
    enum StrictTaskPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict task preference. Its code is unique within a tenant.
    final class StrictTaskPreference {
        var code: String
        var label: String
        var version: Int
        var reviewer: String
        var notes: String
        var allergy: String
        var floorValue: Double
        var budget: Double
        var description: String
        var status: StrictTaskPreferenceStatus

        init(code: String, label: String, version: Int, reviewer: String, notes: String, allergy: String, floorValue: Double, budget: Double, description: String, status: StrictTaskPreferenceStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.reviewer = reviewer
            self.notes = notes
            self.allergy = allergy
            self.floorValue = floorValue
            self.budget = budget
            self.description = description
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

        func canMoveTo(_ next: StrictTaskPreferenceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StrictTaskPreferenceStatus.done || next == StrictTaskPreferenceStatus.failed
            case .done:
                return next == StrictTaskPreferenceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictTaskPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict task preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((budget + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> StrictTaskPreference {
            return StrictTaskPreference(
                code: code,
                label: label,
                version: version,
                reviewer: reviewer,
                notes: notes,
                allergy: allergy,
                floorValue: floorValue,
                budget: budget,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict task preference in status new.
    static func newStrictTaskPreference(_ code: String, label: String) -> StrictTaskPreference {
        return StrictTaskPreference(
            code: code,
            label: label,
            version: 0,
            reviewer: "",
            notes: "",
            allergy: "",
            floorValue: 0.0,
            budget: 0.0,
            description: "",
            status: StrictTaskPreferenceStatus.new
        )
    }
}
