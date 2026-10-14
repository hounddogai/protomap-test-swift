import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual care protocol template is in its life cycle.
    enum ManualCareProtocolTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual care protocol template. Its code is unique within a tenant.
    final class ManualCareProtocolTemplate {
        var code: String
        var label: String
        var weight: Double
        var ward: String
        var dosageMg: Double
        var createdAt: Int
        var visible: Bool
        var status: ManualCareProtocolTemplateStatus

        init(code: String, label: String, weight: Double, ward: String, dosageMg: Double, createdAt: Int, visible: Bool, status: ManualCareProtocolTemplateStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.ward = ward
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.visible = visible
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

        func canMoveTo(_ next: ManualCareProtocolTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ManualCareProtocolTemplateStatus.rejected || next == ManualCareProtocolTemplateStatus.withdrawn
            case .rejected:
                return next == ManualCareProtocolTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCareProtocolTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(createdAt) - weight) * 100).rounded() / 100
        }

        func copyValue() -> ManualCareProtocolTemplate {
            return ManualCareProtocolTemplate(
                code: code,
                label: label,
                weight: weight,
                ward: ward,
                dosageMg: dosageMg,
                createdAt: createdAt,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual care protocol template in status proposed.
    static func newManualCareProtocolTemplate(_ code: String, label: String) -> ManualCareProtocolTemplate {
        return ManualCareProtocolTemplate(
            code: code,
            label: label,
            weight: 0.0,
            ward: "",
            dosageMg: 0.0,
            createdAt: 0,
            visible: false,
            status: ManualCareProtocolTemplateStatus.proposed
        )
    }
}
