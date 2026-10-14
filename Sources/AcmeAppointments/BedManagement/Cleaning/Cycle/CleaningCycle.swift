import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning cycle is in its life cycle.
    enum CleaningCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a cleaning cycle and its current status.
    final class CleaningCycle {
        var code: String
        var name: String
        var minimum: Double
        var createdAt: Int
        var title: String
        var refills: Int
        var clinicianID: String
        var allergy: String
        var status: CleaningCycleStatus

        init(code: String, name: String, minimum: Double, createdAt: Int, title: String, refills: Int, clinicianID: String, allergy: String, status: CleaningCycleStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.createdAt = createdAt
            self.title = title
            self.refills = refills
            self.clinicianID = clinicianID
            self.allergy = allergy
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

        func canMoveTo(_ next: CleaningCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == CleaningCycleStatus.completed
            case .scheduled:
                return next == CleaningCycleStatus.completed
            case .inProgress:
                return next == CleaningCycleStatus.completed
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

        func moveTo(_ next: CleaningCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedVolume() -> Double {
            return ((minimum + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningCycle {
            return CleaningCycle(
                code: code,
                name: name,
                minimum: minimum,
                createdAt: createdAt,
                title: title,
                refills: refills,
                clinicianID: clinicianID,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a cleaning cycle in status planned.
    static func newCleaningCycle(_ code: String, name: String) -> CleaningCycle {
        return CleaningCycle(
            code: code,
            name: name,
            minimum: 0.0,
            createdAt: 0,
            title: "",
            refills: 0,
            clinicianID: "",
            allergy: "",
            status: CleaningCycleStatus.planned
        )
    }
}
