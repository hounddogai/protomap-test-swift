import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered recall assignment is in its life cycle.
    enum TieredRecallAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered recall assignment, with what the planners need to act on it.
    final class TieredRecallAssignment {
        var code: String
        var name: String
        var version: Int
        var updatedAt: Int
        var windowDays: Int
        var clinicianID: String
        var category: String
        var procedureCode: String
        var unit: String
        var status: TieredRecallAssignmentStatus

        init(code: String, name: String, version: Int, updatedAt: Int, windowDays: Int, clinicianID: String, category: String, procedureCode: String, unit: String, status: TieredRecallAssignmentStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.updatedAt = updatedAt
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.category = category
            self.procedureCode = procedureCode
            self.unit = unit
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

        func canMoveTo(_ next: TieredRecallAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TieredRecallAssignmentStatus.reopened || next == TieredRecallAssignmentStatus.archived
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

        func moveTo(_ next: TieredRecallAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered recall assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("tiered recall assignment") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(updatedAt) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredRecallAssignment {
            return TieredRecallAssignment(
                code: code,
                name: name,
                version: version,
                updatedAt: updatedAt,
                windowDays: windowDays,
                clinicianID: clinicianID,
                category: category,
                procedureCode: procedureCode,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered recall assignment in status open.
    static func newTieredRecallAssignment(_ code: String, name: String) -> TieredRecallAssignment {
        return TieredRecallAssignment(
            code: code,
            name: name,
            version: 0,
            updatedAt: 0,
            windowDays: 0,
            clinicianID: "",
            category: "",
            procedureCode: "",
            unit: "",
            status: TieredRecallAssignmentStatus.`open`
        )
    }
}
