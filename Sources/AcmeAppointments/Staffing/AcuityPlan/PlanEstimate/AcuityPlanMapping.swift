import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan mapping is in its life cycle.
    enum AcuityPlanMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a acuity plan mapping and its current status.
    final class AcuityPlanMapping {
        var code: String
        var title: String
        var label: String
        var version: Int
        var visible: Bool
        var encounterID: String
        var threshold: Double
        var dosageMg: Double
        var status: AcuityPlanMappingStatus

        init(code: String, title: String, label: String, version: Int, visible: Bool, encounterID: String, threshold: Double, dosageMg: Double, status: AcuityPlanMappingStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.version = version
            self.visible = visible
            self.encounterID = encounterID
            self.threshold = threshold
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: AcuityPlanMappingStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == AcuityPlanMappingStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("acuity plan mapping") \(code)"
        }

        func projectedValue() -> Double {
            return (dosageMg * threshold * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanMapping {
            return AcuityPlanMapping(
                code: code,
                title: title,
                label: label,
                version: version,
                visible: visible,
                encounterID: encounterID,
                threshold: threshold,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a acuity plan mapping in status open.
    static func newAcuityPlanMapping(_ code: String, title: String) -> AcuityPlanMapping {
        return AcuityPlanMapping(
            code: code,
            title: title,
            label: "",
            version: 0,
            visible: false,
            encounterID: "",
            threshold: 0.0,
            dosageMg: 0.0,
            status: AcuityPlanMappingStatus.`open`
        )
    }
}
