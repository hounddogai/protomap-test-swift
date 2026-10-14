import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict follow up adjustment is in its life cycle.
    enum StrictFollowUpAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a strict follow up adjustment and its current status.
    final class StrictFollowUpAdjustment {
        var code: String
        var label: String
        var region: String
        var specialty: String
        var createdAt: Int
        var approved: Bool
        var diagnosisCode: String
        var encounterID: String
        var visible: Bool
        var allergy: String
        var summary: String
        var status: StrictFollowUpAdjustmentStatus

        init(code: String, label: String, region: String, specialty: String, createdAt: Int, approved: Bool, diagnosisCode: String, encounterID: String, visible: Bool, allergy: String, summary: String, status: StrictFollowUpAdjustmentStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.specialty = specialty
            self.createdAt = createdAt
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.encounterID = encounterID
            self.visible = visible
            self.allergy = allergy
            self.summary = summary
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

        func canMoveTo(_ next: StrictFollowUpAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StrictFollowUpAdjustmentStatus.completed || next == StrictFollowUpAdjustmentStatus.cancelled
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

        func moveTo(_ next: StrictFollowUpAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict follow up adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> StrictFollowUpAdjustment {
            return StrictFollowUpAdjustment(
                code: code,
                label: label,
                region: region,
                specialty: specialty,
                createdAt: createdAt,
                approved: approved,
                diagnosisCode: diagnosisCode,
                encounterID: encounterID,
                visible: visible,
                allergy: allergy,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a strict follow up adjustment in status planned.
    static func newStrictFollowUpAdjustment(_ code: String, label: String) -> StrictFollowUpAdjustment {
        return StrictFollowUpAdjustment(
            code: code,
            label: label,
            region: "",
            specialty: "",
            createdAt: 0,
            approved: false,
            diagnosisCode: "",
            encounterID: "",
            visible: false,
            allergy: "",
            summary: "",
            status: StrictFollowUpAdjustmentStatus.planned
        )
    }
}
