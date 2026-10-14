import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict transfer score is in its life cycle.
    enum StrictTransferScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One strict transfer score, with what the planners need to act on it.
    final class StrictTransferScore {
        var code: String
        var label: String
        var budget: Double
        var clinicianID: String
        var copay: Double
        var status: StrictTransferScoreStatus

        init(code: String, label: String, budget: Double, clinicianID: String, copay: Double, status: StrictTransferScoreStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.clinicianID = clinicianID
            self.copay = copay
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

        func canMoveTo(_ next: StrictTransferScoreStatus) -> Bool {
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
                switch next {
                case .expired:
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

        func moveTo(_ next: StrictTransferScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict transfer score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict transfer score") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((budget + copay) * 100).rounded() / 100
        }

        func copyValue() -> StrictTransferScore {
            return StrictTransferScore(
                code: code,
                label: label,
                budget: budget,
                clinicianID: clinicianID,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict transfer score in status requested.
    static func newStrictTransferScore(_ code: String, label: String) -> StrictTransferScore {
        return StrictTransferScore(
            code: code,
            label: label,
            budget: 0.0,
            clinicianID: "",
            copay: 0.0,
            status: StrictTransferScoreStatus.requested
        )
    }
}
