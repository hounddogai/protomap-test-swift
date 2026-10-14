import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary alert metric is in its life cycle.
    enum PrimaryAlertMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary alert metric. Its code is unique within a tenant.
    final class PrimaryAlertMetric {
        var code: String
        var title: String
        var refills: Int
        var encounterID: String
        var acuity: Int
        var category: String
        var sequence: Int
        var unit: String
        var clinicianID: String
        var status: PrimaryAlertMetricStatus

        init(code: String, title: String, refills: Int, encounterID: String, acuity: Int, category: String, sequence: Int, unit: String, clinicianID: String, status: PrimaryAlertMetricStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.encounterID = encounterID
            self.acuity = acuity
            self.category = category
            self.sequence = sequence
            self.unit = unit
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryAlertMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryAlertMetricStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryAlertMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryAlertMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary alert metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return (Double(acuity) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAlertMetric {
            return PrimaryAlertMetric(
                code: code,
                title: title,
                refills: refills,
                encounterID: encounterID,
                acuity: acuity,
                category: category,
                sequence: sequence,
                unit: unit,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary alert metric in status proposed.
    static func newPrimaryAlertMetric(_ code: String, title: String) -> PrimaryAlertMetric {
        return PrimaryAlertMetric(
            code: code,
            title: title,
            refills: 0,
            encounterID: "",
            acuity: 0,
            category: "",
            sequence: 0,
            unit: "",
            clinicianID: "",
            status: PrimaryAlertMetricStatus.proposed
        )
    }
}
