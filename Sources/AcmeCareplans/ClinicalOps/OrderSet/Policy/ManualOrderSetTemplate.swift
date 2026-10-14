import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual order set template is in its life cycle.
    enum ManualOrderSetTemplateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual order set template. Its code is unique within a tenant.
    final class ManualOrderSetTemplate {
        var code: String
        var label: String
        var unit: String
        var dosageMg: Double
        var capacity: Int
        var ratio: Double
        var revision: Int
        var phone: String
        var acuity: Int
        var status: ManualOrderSetTemplateStatus

        init(code: String, label: String, unit: String, dosageMg: Double, capacity: Int, ratio: Double, revision: Int, phone: String, acuity: Int, status: ManualOrderSetTemplateStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.ratio = ratio
            self.revision = revision
            self.phone = phone
            self.acuity = acuity
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

        func canMoveTo(_ next: ManualOrderSetTemplateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualOrderSetTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual order set template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((Double(revision) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ManualOrderSetTemplate {
            return ManualOrderSetTemplate(
                code: code,
                label: label,
                unit: unit,
                dosageMg: dosageMg,
                capacity: capacity,
                ratio: ratio,
                revision: revision,
                phone: phone,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a manual order set template in status created.
    static func newManualOrderSetTemplate(_ code: String, label: String) -> ManualOrderSetTemplate {
        return ManualOrderSetTemplate(
            code: code,
            label: label,
            unit: "",
            dosageMg: 0.0,
            capacity: 0,
            ratio: 0.0,
            revision: 0,
            phone: "",
            acuity: 0,
            status: ManualOrderSetTemplateStatus.created
        )
    }
}
