import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy remittance milestone is in its life cycle.
    enum LegacyRemittanceMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy remittance milestone. Its code is unique within a tenant.
    final class LegacyRemittanceMilestone {
        var code: String
        var name: String
        var procedureCode: String
        var acuity: Int
        var diagnosisCode: String
        var phone: String
        var description: String
        var status: LegacyRemittanceMilestoneStatus

        init(code: String, name: String, procedureCode: String, acuity: Int, diagnosisCode: String, phone: String, description: String, status: LegacyRemittanceMilestoneStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.phone = phone
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyRemittanceMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacyRemittanceMilestoneStatus.active || next == LegacyRemittanceMilestoneStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyRemittanceMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy remittance milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> LegacyRemittanceMilestone {
            return LegacyRemittanceMilestone(
                code: code,
                name: name,
                procedureCode: procedureCode,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                phone: phone,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy remittance milestone in status draft.
    static func newLegacyRemittanceMilestone(_ code: String, name: String) -> LegacyRemittanceMilestone {
        return LegacyRemittanceMilestone(
            code: code,
            name: name,
            procedureCode: "",
            acuity: 0,
            diagnosisCode: "",
            phone: "",
            description: "",
            status: LegacyRemittanceMilestoneStatus.draft
        )
    }
}
