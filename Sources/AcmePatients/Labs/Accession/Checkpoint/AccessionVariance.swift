import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession variance is in its life cycle.
    enum AccessionVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A accession variance as the accession team keeps it.
    final class AccessionVariance {
        var code: String
        var name: String
        var encounterID: String
        var copay: Double
        var specialty: String
        var status: AccessionVarianceStatus

        init(code: String, name: String, encounterID: String, copay: Double, specialty: String, status: AccessionVarianceStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.copay = copay
            self.specialty = specialty
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

        func canMoveTo(_ next: AccessionVarianceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AccessionVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> AccessionVariance {
            return AccessionVariance(
                code: code,
                name: name,
                encounterID: encounterID,
                copay: copay,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a accession variance in status planned.
    static func newAccessionVariance(_ code: String, name: String) -> AccessionVariance {
        return AccessionVariance(
            code: code,
            name: name,
            encounterID: "",
            copay: 0.0,
            specialty: "",
            status: AccessionVarianceStatus.planned
        )
    }
}
