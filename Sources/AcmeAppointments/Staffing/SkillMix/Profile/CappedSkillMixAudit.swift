import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped skill mix audit is in its life cycle.
    enum CappedSkillMixAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped skill mix audit. Its code is unique within a tenant.
    final class CappedSkillMixAudit {
        var code: String
        var label: String
        var description: String
        var sequence: Int
        var patientRef: String
        var cost: Double
        var channel: String
        var budget: Double
        var notes: String
        var createdAt: Int
        var status: CappedSkillMixAuditStatus

        init(code: String, label: String, description: String, sequence: Int, patientRef: String, cost: Double, channel: String, budget: Double, notes: String, createdAt: Int, status: CappedSkillMixAuditStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.sequence = sequence
            self.patientRef = patientRef
            self.cost = cost
            self.channel = channel
            self.budget = budget
            self.notes = notes
            self.createdAt = createdAt
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

        func canMoveTo(_ next: CappedSkillMixAuditStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedSkillMixAuditStatus.approved || next == CappedSkillMixAuditStatus.rejected
            case .approved:
                return next == CappedSkillMixAuditStatus.rejected || next == CappedSkillMixAuditStatus.withdrawn
            case .rejected:
                return next == CappedSkillMixAuditStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedSkillMixAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped skill mix audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return (Double(createdAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> CappedSkillMixAudit {
            return CappedSkillMixAudit(
                code: code,
                label: label,
                description: description,
                sequence: sequence,
                patientRef: patientRef,
                cost: cost,
                channel: channel,
                budget: budget,
                notes: notes,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped skill mix audit in status proposed.
    static func newCappedSkillMixAudit(_ code: String, label: String) -> CappedSkillMixAudit {
        return CappedSkillMixAudit(
            code: code,
            label: label,
            description: "",
            sequence: 0,
            patientRef: "",
            cost: 0.0,
            channel: "",
            budget: 0.0,
            notes: "",
            createdAt: 0,
            status: CappedSkillMixAuditStatus.proposed
        )
    }
}
