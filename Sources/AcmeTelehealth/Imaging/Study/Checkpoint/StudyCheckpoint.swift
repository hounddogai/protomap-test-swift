import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study checkpoint is in its life cycle.
    enum StudyCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One study checkpoint, with what the planners need to act on it.
    final class StudyCheckpoint {
        var code: String
        var name: String
        var budget: Double
        var ward: String
        var createdAt: Int
        var status: StudyCheckpointStatus

        init(code: String, name: String, budget: Double, ward: String, createdAt: Int, status: StudyCheckpointStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.ward = ward
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudyCheckpointStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StudyCheckpointStatus.published
            case .published:
                return next == StudyCheckpointStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("study checkpoint") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((budget + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> StudyCheckpoint {
            return StudyCheckpoint(
                code: code,
                name: name,
                budget: budget,
                ward: ward,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a study checkpoint in status created.
    static func newStudyCheckpoint(_ code: String, name: String) -> StudyCheckpoint {
        return StudyCheckpoint(
            code: code,
            name: name,
            budget: 0.0,
            ward: "",
            createdAt: 0,
            status: StudyCheckpointStatus.created
        )
    }
}
