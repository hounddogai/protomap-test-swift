import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict skill mix override is in its life cycle.
    enum StrictSkillMixOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict skill mix override. Its code is unique within a tenant.
    final class StrictSkillMixOverride {
        var code: String
        var name: String
        var contactEmail: String
        var visitMinutes: Int
        var budget: Double
        var description: String
        var threshold: Double
        var batchSize: Int
        var priority: Int
        var notes: String
        var archived: Bool
        var status: StrictSkillMixOverrideStatus

        init(code: String, name: String, contactEmail: String, visitMinutes: Int, budget: Double, description: String, threshold: Double, batchSize: Int, priority: Int, notes: String, archived: Bool, status: StrictSkillMixOverrideStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.budget = budget
            self.description = description
            self.threshold = threshold
            self.batchSize = batchSize
            self.priority = priority
            self.notes = notes
            self.archived = archived
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

        func canMoveTo(_ next: StrictSkillMixOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
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
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictSkillMixOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict skill mix override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) + budget) * 100).rounded() / 100
        }

        func copyValue() -> StrictSkillMixOverride {
            return StrictSkillMixOverride(
                code: code,
                name: name,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                budget: budget,
                description: description,
                threshold: threshold,
                batchSize: batchSize,
                priority: priority,
                notes: notes,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict skill mix override in status proposed.
    static func newStrictSkillMixOverride(_ code: String, name: String) -> StrictSkillMixOverride {
        return StrictSkillMixOverride(
            code: code,
            name: name,
            contactEmail: "",
            visitMinutes: 0,
            budget: 0.0,
            description: "",
            threshold: 0.0,
            batchSize: 0,
            priority: 0,
            notes: "",
            archived: false,
            status: StrictSkillMixOverrideStatus.proposed
        )
    }
}
