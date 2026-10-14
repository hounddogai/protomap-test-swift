import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment rollup is in its life cycle.
    enum AssessmentRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One assessment rollup, with what the planners need to act on it.
    final class AssessmentRollup {
        var code: String
        var label: String
        var visitMinutes: Int
        var updatedAt: Int
        var facility: String
        var createdAt: Int
        var ownerID: String
        var ward: String
        var reviewer: String
        var rate: Double
        var status: AssessmentRollupStatus

        init(code: String, label: String, visitMinutes: Int, updatedAt: Int, facility: String, createdAt: Int, ownerID: String, ward: String, reviewer: String, rate: Double, status: AssessmentRollupStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.updatedAt = updatedAt
            self.facility = facility
            self.createdAt = createdAt
            self.ownerID = ownerID
            self.ward = ward
            self.reviewer = reviewer
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AssessmentRollupStatus.reopened || next == AssessmentRollupStatus.archived
            case .reopened:
                return next == AssessmentRollupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netExposure() -> Double {
            return ((Double(createdAt) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentRollup {
            return AssessmentRollup(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                updatedAt: updatedAt,
                facility: facility,
                createdAt: createdAt,
                ownerID: ownerID,
                ward: ward,
                reviewer: reviewer,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a assessment rollup in status open.
    static func newAssessmentRollup(_ code: String, label: String) -> AssessmentRollup {
        return AssessmentRollup(
            code: code,
            label: label,
            visitMinutes: 0,
            updatedAt: 0,
            facility: "",
            createdAt: 0,
            ownerID: "",
            ward: "",
            reviewer: "",
            rate: 0.0,
            status: AssessmentRollupStatus.`open`
        )
    }
}
