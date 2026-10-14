import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global care gap assignment is in its life cycle.
    enum GlobalCareGapAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a global care gap assignment and its current status.
    final class GlobalCareGapAssignment {
        var code: String
        var name: String
        var visitMinutes: Int
        var patientRef: String
        var unit: String
        var archived: Bool
        var ward: String
        var updatedAt: Int
        var reviewer: String
        var budget: Double
        var copay: Double
        var status: GlobalCareGapAssignmentStatus

        init(code: String, name: String, visitMinutes: Int, patientRef: String, unit: String, archived: Bool, ward: String, updatedAt: Int, reviewer: String, budget: Double, copay: Double, status: GlobalCareGapAssignmentStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.patientRef = patientRef
            self.unit = unit
            self.archived = archived
            self.ward = ward
            self.updatedAt = updatedAt
            self.reviewer = reviewer
            self.budget = budget
            self.copay = copay
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

        func canMoveTo(_ next: GlobalCareGapAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalCareGapAssignmentStatus.completed || next == GlobalCareGapAssignmentStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == GlobalCareGapAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCareGapAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care gap assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global care gap assignment") \(code)"
        }

        func netValue() -> Double {
            return (budget * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareGapAssignment {
            return GlobalCareGapAssignment(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                patientRef: patientRef,
                unit: unit,
                archived: archived,
                ward: ward,
                updatedAt: updatedAt,
                reviewer: reviewer,
                budget: budget,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global care gap assignment in status planned.
    static func newGlobalCareGapAssignment(_ code: String, name: String) -> GlobalCareGapAssignment {
        return GlobalCareGapAssignment(
            code: code,
            name: name,
            visitMinutes: 0,
            patientRef: "",
            unit: "",
            archived: false,
            ward: "",
            updatedAt: 0,
            reviewer: "",
            budget: 0.0,
            copay: 0.0,
            status: GlobalCareGapAssignmentStatus.planned
        )
    }
}
