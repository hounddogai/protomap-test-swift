import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan estimate is in its life cycle.
    enum AcuityPlanEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One acuity plan estimate, with what the planners need to act on it.
    final class AcuityPlanEstimate {
        var code: String
        var label: String
        var ward: String
        var facility: String
        var version: Int
        var status: AcuityPlanEstimateStatus

        init(code: String, label: String, ward: String, facility: String, version: Int, status: AcuityPlanEstimateStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.facility = facility
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanEstimateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AcuityPlanEstimateStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AcuityPlanEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> AcuityPlanEstimate {
            return AcuityPlanEstimate(
                code: code,
                label: label,
                ward: ward,
                facility: facility,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a acuity plan estimate in status created.
    static func newAcuityPlanEstimate(_ code: String, label: String) -> AcuityPlanEstimate {
        return AcuityPlanEstimate(
            code: code,
            label: label,
            ward: "",
            facility: "",
            version: 0,
            status: AcuityPlanEstimateStatus.created
        )
    }
}
