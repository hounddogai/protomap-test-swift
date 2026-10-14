import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending result policy is in its life cycle.
    enum PendingResultPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending result policy. Its code is unique within a tenant.
    final class PendingResultPolicy {
        var code: String
        var name: String
        var patientRef: String
        var budget: Double
        var retries: Int
        var archived: Bool
        var diagnosisCode: String
        var refills: Int
        var endsAt: Int
        var visible: Bool
        var description: String
        var status: PendingResultPolicyStatus

        init(code: String, name: String, patientRef: String, budget: Double, retries: Int, archived: Bool, diagnosisCode: String, refills: Int, endsAt: Int, visible: Bool, description: String, status: PendingResultPolicyStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.budget = budget
            self.retries = retries
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.refills = refills
            self.endsAt = endsAt
            self.visible = visible
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

        func canMoveTo(_ next: PendingResultPolicyStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PendingResultPolicyStatus.active || next == PendingResultPolicyStatus.closed
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

        func moveTo(_ next: PendingResultPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending result policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return (Double(refills) * budget * 100).rounded() / 100
        }

        func copyValue() -> PendingResultPolicy {
            return PendingResultPolicy(
                code: code,
                name: name,
                patientRef: patientRef,
                budget: budget,
                retries: retries,
                archived: archived,
                diagnosisCode: diagnosisCode,
                refills: refills,
                endsAt: endsAt,
                visible: visible,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending result policy in status draft.
    static func newPendingResultPolicy(_ code: String, name: String) -> PendingResultPolicy {
        return PendingResultPolicy(
            code: code,
            name: name,
            patientRef: "",
            budget: 0.0,
            retries: 0,
            archived: false,
            diagnosisCode: "",
            refills: 0,
            endsAt: 0,
            visible: false,
            description: "",
            status: PendingResultPolicyStatus.draft
        )
    }
}
