import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled cleaning assignment is in its life cycle.
    enum ScheduledCleaningAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a scheduled cleaning assignment and its current status.
    final class ScheduledCleaningAssignment {
        var code: String
        var name: String
        var copay: Double
        var budget: Double
        var phone: String
        var tags: [String]
        var allergy: String
        var visitMinutes: Int
        var dosageMg: Double
        var description: String
        var limit: Int
        var status: ScheduledCleaningAssignmentStatus

        init(code: String, name: String, copay: Double, budget: Double, phone: String, tags: [String], allergy: String, visitMinutes: Int, dosageMg: Double, description: String, limit: Int, status: ScheduledCleaningAssignmentStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.budget = budget
            self.phone = phone
            self.tags = tags
            self.allergy = allergy
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
            self.description = description
            self.limit = limit
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

        func canMoveTo(_ next: ScheduledCleaningAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
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

        func moveTo(_ next: ScheduledCleaningAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled cleaning assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveVolume() -> Double {
            return ((Double(limit) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCleaningAssignment {
            return ScheduledCleaningAssignment(
                code: code,
                name: name,
                copay: copay,
                budget: budget,
                phone: phone,
                tags: tags,
                allergy: allergy,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                description: description,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled cleaning assignment in status requested.
    static func newScheduledCleaningAssignment(_ code: String, name: String) -> ScheduledCleaningAssignment {
        return ScheduledCleaningAssignment(
            code: code,
            name: name,
            copay: 0.0,
            budget: 0.0,
            phone: "",
            tags: [],
            allergy: "",
            visitMinutes: 0,
            dosageMg: 0.0,
            description: "",
            limit: 0,
            status: ScheduledCleaningAssignmentStatus.requested
        )
    }
}
