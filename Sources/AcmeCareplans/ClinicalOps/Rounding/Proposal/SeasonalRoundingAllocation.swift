import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal rounding allocation is in its life cycle.
    enum SeasonalRoundingAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal rounding allocation as the rounding team keeps it.
    final class SeasonalRoundingAllocation {
        var code: String
        var title: String
        var sequence: Int
        var specialty: String
        var encounterID: String
        var status: SeasonalRoundingAllocationStatus

        init(code: String, title: String, sequence: Int, specialty: String, encounterID: String, status: SeasonalRoundingAllocationStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.specialty = specialty
            self.encounterID = encounterID
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

        func canMoveTo(_ next: SeasonalRoundingAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == SeasonalRoundingAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRoundingAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal rounding allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> SeasonalRoundingAllocation {
            return SeasonalRoundingAllocation(
                code: code,
                title: title,
                sequence: sequence,
                specialty: specialty,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal rounding allocation in status requested.
    static func newSeasonalRoundingAllocation(_ code: String, title: String) -> SeasonalRoundingAllocation {
        return SeasonalRoundingAllocation(
            code: code,
            title: title,
            sequence: 0,
            specialty: "",
            encounterID: "",
            status: SeasonalRoundingAllocationStatus.requested
        )
    }
}
