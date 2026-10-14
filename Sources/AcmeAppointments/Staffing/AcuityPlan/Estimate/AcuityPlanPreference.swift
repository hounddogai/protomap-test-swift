import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan preference is in its life cycle.
    enum AcuityPlanPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A acuity plan preference as the acuity plan team keeps it.
    final class AcuityPlanPreference {
        var code: String
        var name: String
        var allergy: String
        var batchSize: Int
        var label: String
        var facility: String
        var description: String
        var status: AcuityPlanPreferenceStatus

        init(code: String, name: String, allergy: String, batchSize: Int, label: String, facility: String, description: String, status: AcuityPlanPreferenceStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.batchSize = batchSize
            self.label = label
            self.facility = facility
            self.description = description
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

        func canMoveTo(_ next: AcuityPlanPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AcuityPlanPreferenceStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AcuityPlanPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> AcuityPlanPreference {
            return AcuityPlanPreference(
                code: code,
                name: name,
                allergy: allergy,
                batchSize: batchSize,
                label: label,
                facility: facility,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a acuity plan preference in status open.
    static func newAcuityPlanPreference(_ code: String, name: String) -> AcuityPlanPreference {
        return AcuityPlanPreference(
            code: code,
            name: name,
            allergy: "",
            batchSize: 0,
            label: "",
            facility: "",
            description: "",
            status: AcuityPlanPreferenceStatus.`open`
        )
    }
}
