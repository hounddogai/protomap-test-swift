import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority group is in its life cycle.
    enum PriorityGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A priority group. Its code is unique within a tenant.
    final class PriorityGroup {
        var code: String
        var label: String
        var allergy: String
        var archived: Bool
        var diagnosisCode: String
        var createdAt: Int
        var retries: Int
        var refills: Int
        var acuity: Int
        var discount: Double
        var visible: Bool
        var status: PriorityGroupStatus

        init(code: String, label: String, allergy: String, archived: Bool, diagnosisCode: String, createdAt: Int, retries: Int, refills: Int, acuity: Int, discount: Double, visible: Bool, status: PriorityGroupStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.retries = retries
            self.refills = refills
            self.acuity = acuity
            self.discount = discount
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PriorityGroupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return ((discount - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityGroup {
            return PriorityGroup(
                code: code,
                label: label,
                allergy: allergy,
                archived: archived,
                diagnosisCode: diagnosisCode,
                createdAt: createdAt,
                retries: retries,
                refills: refills,
                acuity: acuity,
                discount: discount,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a priority group in status requested.
    static func newPriorityGroup(_ code: String, label: String) -> PriorityGroup {
        return PriorityGroup(
            code: code,
            label: label,
            allergy: "",
            archived: false,
            diagnosisCode: "",
            createdAt: 0,
            retries: 0,
            refills: 0,
            acuity: 0,
            discount: 0.0,
            visible: false,
            status: PriorityGroupStatus.requested
        )
    }
}
