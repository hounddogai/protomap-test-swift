import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan template is in its life cycle.
    enum AcuityPlanTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A acuity plan template. Its code is unique within a tenant.
    final class AcuityPlanTemplate {
        var code: String
        var label: String
        var maximum: Double
        var bed: String
        var sequence: Int
        var ward: String
        var unit: String
        var segment: String
        var status: AcuityPlanTemplateStatus

        init(code: String, label: String, maximum: Double, bed: String, sequence: Int, ward: String, unit: String, segment: String, status: AcuityPlanTemplateStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.bed = bed
            self.sequence = sequence
            self.ward = ward
            self.unit = unit
            self.segment = segment
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

        func canMoveTo(_ next: AcuityPlanTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AcuityPlanTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return (Double(sequence) * maximum * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanTemplate {
            return AcuityPlanTemplate(
                code: code,
                label: label,
                maximum: maximum,
                bed: bed,
                sequence: sequence,
                ward: ward,
                unit: unit,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a acuity plan template in status proposed.
    static func newAcuityPlanTemplate(_ code: String, label: String) -> AcuityPlanTemplate {
        return AcuityPlanTemplate(
            code: code,
            label: label,
            maximum: 0.0,
            bed: "",
            sequence: 0,
            ward: "",
            unit: "",
            segment: "",
            status: AcuityPlanTemplateStatus.proposed
        )
    }
}
