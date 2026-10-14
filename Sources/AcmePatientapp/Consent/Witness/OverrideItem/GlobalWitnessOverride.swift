import AcmePlatform
import Foundation

extension Consent {
    /// Where a global witness override is in its life cycle.
    enum GlobalWitnessOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a global witness override and its current status.
    final class GlobalWitnessOverride {
        var code: String
        var label: String
        var archived: Bool
        var minimum: Double
        var sequence: Int
        var segment: String
        var attempts: Int
        var encounterID: String
        var checksum: String
        var pinned: Bool
        var status: GlobalWitnessOverrideStatus

        init(code: String, label: String, archived: Bool, minimum: Double, sequence: Int, segment: String, attempts: Int, encounterID: String, checksum: String, pinned: Bool, status: GlobalWitnessOverrideStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.minimum = minimum
            self.sequence = sequence
            self.segment = segment
            self.attempts = attempts
            self.encounterID = encounterID
            self.checksum = checksum
            self.pinned = pinned
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

        func canMoveTo(_ next: GlobalWitnessOverrideStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalWitnessOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global witness override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return (minimum * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> GlobalWitnessOverride {
            return GlobalWitnessOverride(
                code: code,
                label: label,
                archived: archived,
                minimum: minimum,
                sequence: sequence,
                segment: segment,
                attempts: attempts,
                encounterID: encounterID,
                checksum: checksum,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global witness override in status requested.
    static func newGlobalWitnessOverride(_ code: String, label: String) -> GlobalWitnessOverride {
        return GlobalWitnessOverride(
            code: code,
            label: label,
            archived: false,
            minimum: 0.0,
            sequence: 0,
            segment: "",
            attempts: 0,
            encounterID: "",
            checksum: "",
            pinned: false,
            status: GlobalWitnessOverrideStatus.requested
        )
    }
}
