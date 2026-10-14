import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy assessment milestone is in its life cycle.
    enum LegacyAssessmentMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy assessment milestone and its current status.
    final class LegacyAssessmentMilestone {
        var code: String
        var name: String
        var budget: Double
        var description: String
        var checksum: String
        var durationMinutes: Int
        var region: String
        var ceiling: Double
        var unit: String
        var status: LegacyAssessmentMilestoneStatus

        init(code: String, name: String, budget: Double, description: String, checksum: String, durationMinutes: Int, region: String, ceiling: Double, unit: String, status: LegacyAssessmentMilestoneStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.description = description
            self.checksum = checksum
            self.durationMinutes = durationMinutes
            self.region = region
            self.ceiling = ceiling
            self.unit = unit
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

        func canMoveTo(_ next: LegacyAssessmentMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LegacyAssessmentMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAssessmentMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy assessment milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(durationMinutes) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAssessmentMilestone {
            return LegacyAssessmentMilestone(
                code: code,
                name: name,
                budget: budget,
                description: description,
                checksum: checksum,
                durationMinutes: durationMinutes,
                region: region,
                ceiling: ceiling,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy assessment milestone in status planned.
    static func newLegacyAssessmentMilestone(_ code: String, name: String) -> LegacyAssessmentMilestone {
        return LegacyAssessmentMilestone(
            code: code,
            name: name,
            budget: 0.0,
            description: "",
            checksum: "",
            durationMinutes: 0,
            region: "",
            ceiling: 0.0,
            unit: "",
            status: LegacyAssessmentMilestoneStatus.planned
        )
    }
}
