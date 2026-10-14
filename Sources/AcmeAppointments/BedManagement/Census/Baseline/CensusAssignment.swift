import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census assignment is in its life cycle.
    enum CensusAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a census assignment and its current status.
    final class CensusAssignment {
        var code: String
        var title: String
        var budget: Double
        var ownerID: String
        var batchSize: Int
        var active: Bool
        var refills: Int
        var minimum: Double
        var windowDays: Int
        var allergy: String
        var status: CensusAssignmentStatus

        init(code: String, title: String, budget: Double, ownerID: String, batchSize: Int, active: Bool, refills: Int, minimum: Double, windowDays: Int, allergy: String, status: CensusAssignmentStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.active = active
            self.refills = refills
            self.minimum = minimum
            self.windowDays = windowDays
            self.allergy = allergy
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

        func canMoveTo(_ next: CensusAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == CensusAssignmentStatus.active || next == CensusAssignmentStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CensusAssignmentStatus.suspended || next == CensusAssignmentStatus.closed
            case .suspended:
                return next == CensusAssignmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(batchSize) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> CensusAssignment {
            return CensusAssignment(
                code: code,
                title: title,
                budget: budget,
                ownerID: ownerID,
                batchSize: batchSize,
                active: active,
                refills: refills,
                minimum: minimum,
                windowDays: windowDays,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a census assignment in status draft.
    static func newCensusAssignment(_ code: String, title: String) -> CensusAssignment {
        return CensusAssignment(
            code: code,
            title: title,
            budget: 0.0,
            ownerID: "",
            batchSize: 0,
            active: false,
            refills: 0,
            minimum: 0.0,
            windowDays: 0,
            allergy: "",
            status: CensusAssignmentStatus.draft
        )
    }
}
