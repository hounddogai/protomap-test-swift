import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary skill mix score is in its life cycle.
    enum PrimarySkillMixScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary skill mix score. Its code is unique within a tenant.
    final class PrimarySkillMixScore {
        var code: String
        var name: String
        var copay: Double
        var facility: String
        var createdAt: Int
        var contactEmail: String
        var procedureCode: String
        var archived: Bool
        var ceiling: Double
        var status: PrimarySkillMixScoreStatus

        init(code: String, name: String, copay: Double, facility: String, createdAt: Int, contactEmail: String, procedureCode: String, archived: Bool, ceiling: Double, status: PrimarySkillMixScoreStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.facility = facility
            self.createdAt = createdAt
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.archived = archived
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimarySkillMixScoreStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PrimarySkillMixScoreStatus.stopped
            case .ready:
                return next == PrimarySkillMixScoreStatus.draining
            case .draining:
                return next == PrimarySkillMixScoreStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySkillMixScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary skill mix score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary skill mix score") \(code)"
        }

        func netLoad() -> Double {
            return (copay * ceiling * 100).rounded() / 100
        }

        func copyValue() -> PrimarySkillMixScore {
            return PrimarySkillMixScore(
                code: code,
                name: name,
                copay: copay,
                facility: facility,
                createdAt: createdAt,
                contactEmail: contactEmail,
                procedureCode: procedureCode,
                archived: archived,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a primary skill mix score in status idle.
    static func newPrimarySkillMixScore(_ code: String, name: String) -> PrimarySkillMixScore {
        return PrimarySkillMixScore(
            code: code,
            name: name,
            copay: 0.0,
            facility: "",
            createdAt: 0,
            contactEmail: "",
            procedureCode: "",
            archived: false,
            ceiling: 0.0,
            status: PrimarySkillMixScoreStatus.idle
        )
    }
}
