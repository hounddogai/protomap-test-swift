import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default skill mix assignment is in its life cycle.
    enum DefaultSkillMixAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A default skill mix assignment as the skill mix team keeps it.
    final class DefaultSkillMixAssignment {
        var code: String
        var name: String
        var phone: String
        var updatedAt: Int
        var maximum: Double
        var cost: Double
        var ward: String
        var batchSize: Int
        var windowDays: Int
        var status: DefaultSkillMixAssignmentStatus

        init(code: String, name: String, phone: String, updatedAt: Int, maximum: Double, cost: Double, ward: String, batchSize: Int, windowDays: Int, status: DefaultSkillMixAssignmentStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.updatedAt = updatedAt
            self.maximum = maximum
            self.cost = cost
            self.ward = ward
            self.batchSize = batchSize
            self.windowDays = windowDays
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

        func canMoveTo(_ next: DefaultSkillMixAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DefaultSkillMixAssignmentStatus.suspended || next == DefaultSkillMixAssignmentStatus.closed
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

        func moveTo(_ next: DefaultSkillMixAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default skill mix assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default skill mix assignment") \(code)"
        }

        func weightedVolume() -> Double {
            return ((cost + maximum) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSkillMixAssignment {
            return DefaultSkillMixAssignment(
                code: code,
                name: name,
                phone: phone,
                updatedAt: updatedAt,
                maximum: maximum,
                cost: cost,
                ward: ward,
                batchSize: batchSize,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default skill mix assignment in status draft.
    static func newDefaultSkillMixAssignment(_ code: String, name: String) -> DefaultSkillMixAssignment {
        return DefaultSkillMixAssignment(
            code: code,
            name: name,
            phone: "",
            updatedAt: 0,
            maximum: 0.0,
            cost: 0.0,
            ward: "",
            batchSize: 0,
            windowDays: 0,
            status: DefaultSkillMixAssignmentStatus.draft
        )
    }
}
