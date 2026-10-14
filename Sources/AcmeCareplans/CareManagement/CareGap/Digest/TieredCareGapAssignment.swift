import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered care gap assignment is in its life cycle.
    enum TieredCareGapAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered care gap assignment, with what the planners need to act on it.
    final class TieredCareGapAssignment {
        var code: String
        var name: String
        var category: String
        var budget: Double
        var minimum: Double
        var facility: String
        var tags: [String]
        var ownerID: String
        var status: TieredCareGapAssignmentStatus

        init(code: String, name: String, category: String, budget: Double, minimum: Double, facility: String, tags: [String], ownerID: String, status: TieredCareGapAssignmentStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.budget = budget
            self.minimum = minimum
            self.facility = facility
            self.tags = tags
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredCareGapAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredCareGapAssignmentStatus.inReview || next == TieredCareGapAssignmentStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TieredCareGapAssignmentStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: TieredCareGapAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care gap assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered care gap assignment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((minimum + budget) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareGapAssignment {
            return TieredCareGapAssignment(
                code: code,
                name: name,
                category: category,
                budget: budget,
                minimum: minimum,
                facility: facility,
                tags: tags,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered care gap assignment in status open.
    static func newTieredCareGapAssignment(_ code: String, name: String) -> TieredCareGapAssignment {
        return TieredCareGapAssignment(
            code: code,
            name: name,
            category: "",
            budget: 0.0,
            minimum: 0.0,
            facility: "",
            tags: [],
            ownerID: "",
            status: TieredCareGapAssignmentStatus.`open`
        )
    }
}
