import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default risk score estimate is in its life cycle.
    enum DefaultRiskScoreEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default risk score estimate. Its code is unique within a tenant.
    final class DefaultRiskScoreEstimate {
        var code: String
        var label: String
        var encounterID: String
        var unit: String
        var bed: String
        var updatedAt: Int
        var threshold: Double
        var contactEmail: String
        var ward: String
        var archived: Bool
        var clinicianID: String
        var status: DefaultRiskScoreEstimateStatus

        init(code: String, label: String, encounterID: String, unit: String, bed: String, updatedAt: Int, threshold: Double, contactEmail: String, ward: String, archived: Bool, clinicianID: String, status: DefaultRiskScoreEstimateStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.unit = unit
            self.bed = bed
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.contactEmail = contactEmail
            self.ward = ward
            self.archived = archived
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: DefaultRiskScoreEstimateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultRiskScoreEstimateStatus.inProgress
            case .inProgress:
                return next == DefaultRiskScoreEstimateStatus.completed || next == DefaultRiskScoreEstimateStatus.cancelled
            case .completed:
                return next == DefaultRiskScoreEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRiskScoreEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default risk score estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("default risk score estimate") \(code)"
        }

        func projectedLoad() -> Double {
            return ((threshold - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRiskScoreEstimate {
            return DefaultRiskScoreEstimate(
                code: code,
                label: label,
                encounterID: encounterID,
                unit: unit,
                bed: bed,
                updatedAt: updatedAt,
                threshold: threshold,
                contactEmail: contactEmail,
                ward: ward,
                archived: archived,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a default risk score estimate in status planned.
    static func newDefaultRiskScoreEstimate(_ code: String, label: String) -> DefaultRiskScoreEstimate {
        return DefaultRiskScoreEstimate(
            code: code,
            label: label,
            encounterID: "",
            unit: "",
            bed: "",
            updatedAt: 0,
            threshold: 0.0,
            contactEmail: "",
            ward: "",
            archived: false,
            clinicianID: "",
            status: DefaultRiskScoreEstimateStatus.planned
        )
    }
}
