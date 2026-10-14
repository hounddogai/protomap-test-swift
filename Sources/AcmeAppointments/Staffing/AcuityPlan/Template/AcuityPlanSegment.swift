import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan segment is in its life cycle.
    enum AcuityPlanSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a acuity plan segment and its current status.
    final class AcuityPlanSegment {
        var code: String
        var label: String
        var ratio: Double
        var rate: Double
        var reviewer: String
        var acuity: Int
        var expiresAt: Int
        var description: String
        var updatedAt: Int
        var clinicianID: String
        var attempts: Int
        var status: AcuityPlanSegmentStatus

        init(code: String, label: String, ratio: Double, rate: Double, reviewer: String, acuity: Int, expiresAt: Int, description: String, updatedAt: Int, clinicianID: String, attempts: Int, status: AcuityPlanSegmentStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.rate = rate
            self.reviewer = reviewer
            self.acuity = acuity
            self.expiresAt = expiresAt
            self.description = description
            self.updatedAt = updatedAt
            self.clinicianID = clinicianID
            self.attempts = attempts
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

        func canMoveTo(_ next: AcuityPlanSegmentStatus) -> Bool {
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
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AcuityPlanSegmentStatus.completed || next == AcuityPlanSegmentStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: AcuityPlanSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return ((rate - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanSegment {
            return AcuityPlanSegment(
                code: code,
                label: label,
                ratio: ratio,
                rate: rate,
                reviewer: reviewer,
                acuity: acuity,
                expiresAt: expiresAt,
                description: description,
                updatedAt: updatedAt,
                clinicianID: clinicianID,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan segment in status planned.
    static func newAcuityPlanSegment(_ code: String, label: String) -> AcuityPlanSegment {
        return AcuityPlanSegment(
            code: code,
            label: label,
            ratio: 0.0,
            rate: 0.0,
            reviewer: "",
            acuity: 0,
            expiresAt: 0,
            description: "",
            updatedAt: 0,
            clinicianID: "",
            attempts: 0,
            status: AcuityPlanSegmentStatus.planned
        )
    }
}
