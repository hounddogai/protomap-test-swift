import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict skill mix audit is in its life cycle.
    enum StrictSkillMixAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict skill mix audit as the skill mix team keeps it.
    final class StrictSkillMixAudit {
        var code: String
        var name: String
        var description: String
        var cost: Double
        var weight: Double
        var reviewer: String
        var procedureCode: String
        var source: String
        var tags: [String]
        var status: StrictSkillMixAuditStatus

        init(code: String, name: String, description: String, cost: Double, weight: Double, reviewer: String, procedureCode: String, source: String, tags: [String], status: StrictSkillMixAuditStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.cost = cost
            self.weight = weight
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.source = source
            self.tags = tags
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

        func canMoveTo(_ next: StrictSkillMixAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictSkillMixAuditStatus.revoked || next == StrictSkillMixAuditStatus.expired
            case .granted:
                return next == StrictSkillMixAuditStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: StrictSkillMixAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict skill mix audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedExposure() -> Double {
            return (cost * weight * 100).rounded() / 100
        }

        func copyValue() -> StrictSkillMixAudit {
            return StrictSkillMixAudit(
                code: code,
                name: name,
                description: description,
                cost: cost,
                weight: weight,
                reviewer: reviewer,
                procedureCode: procedureCode,
                source: source,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a strict skill mix audit in status requested.
    static func newStrictSkillMixAudit(_ code: String, name: String) -> StrictSkillMixAudit {
        return StrictSkillMixAudit(
            code: code,
            name: name,
            description: "",
            cost: 0.0,
            weight: 0.0,
            reviewer: "",
            procedureCode: "",
            source: "",
            tags: [],
            status: StrictSkillMixAuditStatus.requested
        )
    }
}
