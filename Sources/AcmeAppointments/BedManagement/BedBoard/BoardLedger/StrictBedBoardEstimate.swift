import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict bed board estimate is in its life cycle.
    enum StrictBedBoardEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One strict bed board estimate, with what the planners need to act on it.
    final class StrictBedBoardEstimate {
        var code: String
        var name: String
        var margin: Double
        var specialty: String
        var retries: Int
        var ratio: Double
        var dosageMg: Double
        var revision: Int
        var archived: Bool
        var description: String
        var status: StrictBedBoardEstimateStatus

        init(code: String, name: String, margin: Double, specialty: String, retries: Int, ratio: Double, dosageMg: Double, revision: Int, archived: Bool, description: String, status: StrictBedBoardEstimateStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.specialty = specialty
            self.retries = retries
            self.ratio = ratio
            self.dosageMg = dosageMg
            self.revision = revision
            self.archived = archived
            self.description = description
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

        func canMoveTo(_ next: StrictBedBoardEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictBedBoardEstimateStatus.scheduled || next == StrictBedBoardEstimateStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StrictBedBoardEstimateStatus.completed || next == StrictBedBoardEstimateStatus.cancelled
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

        func moveTo(_ next: StrictBedBoardEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict bed board estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveVolume() -> Double {
            return (Double(retries) * margin * 100).rounded() / 100
        }

        func copyValue() -> StrictBedBoardEstimate {
            return StrictBedBoardEstimate(
                code: code,
                name: name,
                margin: margin,
                specialty: specialty,
                retries: retries,
                ratio: ratio,
                dosageMg: dosageMg,
                revision: revision,
                archived: archived,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict bed board estimate in status planned.
    static func newStrictBedBoardEstimate(_ code: String, name: String) -> StrictBedBoardEstimate {
        return StrictBedBoardEstimate(
            code: code,
            name: name,
            margin: 0.0,
            specialty: "",
            retries: 0,
            ratio: 0.0,
            dosageMg: 0.0,
            revision: 0,
            archived: false,
            description: "",
            status: StrictBedBoardEstimateStatus.planned
        )
    }
}
