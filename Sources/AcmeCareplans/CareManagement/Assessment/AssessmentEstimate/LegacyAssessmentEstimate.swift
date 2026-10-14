import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy assessment estimate is in its life cycle.
    enum LegacyAssessmentEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy assessment estimate. Its code is unique within a tenant.
    final class LegacyAssessmentEstimate {
        var code: String
        var title: String
        var facility: String
        var checksum: String
        var reviewer: String
        var minimum: Double
        var status: LegacyAssessmentEstimateStatus

        init(code: String, title: String, facility: String, checksum: String, reviewer: String, minimum: Double, status: LegacyAssessmentEstimateStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.checksum = checksum
            self.reviewer = reviewer
            self.minimum = minimum
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

        func canMoveTo(_ next: LegacyAssessmentEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyAssessmentEstimateStatus.scheduled
            case .scheduled:
                return next == LegacyAssessmentEstimateStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LegacyAssessmentEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAssessmentEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy assessment estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> LegacyAssessmentEstimate {
            return LegacyAssessmentEstimate(
                code: code,
                title: title,
                facility: facility,
                checksum: checksum,
                reviewer: reviewer,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy assessment estimate in status planned.
    static func newLegacyAssessmentEstimate(_ code: String, title: String) -> LegacyAssessmentEstimate {
        return LegacyAssessmentEstimate(
            code: code,
            title: title,
            facility: "",
            checksum: "",
            reviewer: "",
            minimum: 0.0,
            status: LegacyAssessmentEstimateStatus.planned
        )
    }
}
