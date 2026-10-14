import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global skill mix record is in its life cycle.
    enum GlobalSkillMixRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a global skill mix record and its current status.
    final class GlobalSkillMixRecord {
        var code: String
        var label: String
        var updatedAt: Int
        var score: Double
        var minimum: Double
        var quantity: Int
        var budget: Double
        var source: String
        var name: String
        var contactEmail: String
        var startsAt: Int
        var status: GlobalSkillMixRecordStatus

        init(code: String, label: String, updatedAt: Int, score: Double, minimum: Double, quantity: Int, budget: Double, source: String, name: String, contactEmail: String, startsAt: Int, status: GlobalSkillMixRecordStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.score = score
            self.minimum = minimum
            self.quantity = quantity
            self.budget = budget
            self.source = source
            self.name = name
            self.contactEmail = contactEmail
            self.startsAt = startsAt
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

        func canMoveTo(_ next: GlobalSkillMixRecordStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalSkillMixRecordStatus.revoked || next == GlobalSkillMixRecordStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalSkillMixRecordStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalSkillMixRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global skill mix record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return (score * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSkillMixRecord {
            return GlobalSkillMixRecord(
                code: code,
                label: label,
                updatedAt: updatedAt,
                score: score,
                minimum: minimum,
                quantity: quantity,
                budget: budget,
                source: source,
                name: name,
                contactEmail: contactEmail,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global skill mix record in status requested.
    static func newGlobalSkillMixRecord(_ code: String, label: String) -> GlobalSkillMixRecord {
        return GlobalSkillMixRecord(
            code: code,
            label: label,
            updatedAt: 0,
            score: 0.0,
            minimum: 0.0,
            quantity: 0,
            budget: 0.0,
            source: "",
            name: "",
            contactEmail: "",
            startsAt: 0,
            status: GlobalSkillMixRecordStatus.requested
        )
    }
}
