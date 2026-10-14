import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered skill mix digest is in its life cycle.
    enum TieredSkillMixDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered skill mix digest as the skill mix team keeps it.
    final class TieredSkillMixDigest {
        var code: String
        var label: String
        var approved: Bool
        var category: String
        var margin: Double
        var startsAt: Int
        var createdAt: Int
        var endsAt: Int
        var title: String
        var visitMinutes: Int
        var dosageMg: Double
        var status: TieredSkillMixDigestStatus

        init(code: String, label: String, approved: Bool, category: String, margin: Double, startsAt: Int, createdAt: Int, endsAt: Int, title: String, visitMinutes: Int, dosageMg: Double, status: TieredSkillMixDigestStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.category = category
            self.margin = margin
            self.startsAt = startsAt
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.title = title
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredSkillMixDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredSkillMixDigestStatus.cancelled
            case .scheduled:
                return next == TieredSkillMixDigestStatus.inProgress || next == TieredSkillMixDigestStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TieredSkillMixDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered skill mix digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((Double(createdAt) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> TieredSkillMixDigest {
            return TieredSkillMixDigest(
                code: code,
                label: label,
                approved: approved,
                category: category,
                margin: margin,
                startsAt: startsAt,
                createdAt: createdAt,
                endsAt: endsAt,
                title: title,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered skill mix digest in status planned.
    static func newTieredSkillMixDigest(_ code: String, label: String) -> TieredSkillMixDigest {
        return TieredSkillMixDigest(
            code: code,
            label: label,
            approved: false,
            category: "",
            margin: 0.0,
            startsAt: 0,
            createdAt: 0,
            endsAt: 0,
            title: "",
            visitMinutes: 0,
            dosageMg: 0.0,
            status: TieredSkillMixDigestStatus.planned
        )
    }
}
