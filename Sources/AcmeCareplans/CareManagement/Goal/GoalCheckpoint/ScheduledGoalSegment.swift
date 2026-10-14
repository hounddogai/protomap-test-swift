import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled goal segment is in its life cycle.
    enum ScheduledGoalSegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a scheduled goal segment and its current status.
    final class ScheduledGoalSegment {
        var code: String
        var name: String
        var expiresAt: Int
        var allergy: String
        var capacity: Int
        var notes: String
        var dosageMg: Double
        var status: ScheduledGoalSegmentStatus

        init(code: String, name: String, expiresAt: Int, allergy: String, capacity: Int, notes: String, dosageMg: Double, status: ScheduledGoalSegmentStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.capacity = capacity
            self.notes = notes
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledGoalSegmentStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledGoalSegmentStatus.done
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledGoalSegmentStatus.done || next == ScheduledGoalSegmentStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledGoalSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled goal segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return (dosageMg * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledGoalSegment {
            return ScheduledGoalSegment(
                code: code,
                name: name,
                expiresAt: expiresAt,
                allergy: allergy,
                capacity: capacity,
                notes: notes,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled goal segment in status new.
    static func newScheduledGoalSegment(_ code: String, name: String) -> ScheduledGoalSegment {
        return ScheduledGoalSegment(
            code: code,
            name: name,
            expiresAt: 0,
            allergy: "",
            capacity: 0,
            notes: "",
            dosageMg: 0.0,
            status: ScheduledGoalSegmentStatus.new
        )
    }
}
