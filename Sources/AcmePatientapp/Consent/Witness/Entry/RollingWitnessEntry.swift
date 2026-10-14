import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling witness entry is in its life cycle.
    enum RollingWitnessEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling witness entry as the witness team keeps it.
    final class RollingWitnessEntry {
        var code: String
        var name: String
        var approved: Bool
        var notes: String
        var maximum: Double
        var margin: Double
        var status: RollingWitnessEntryStatus

        init(code: String, name: String, approved: Bool, notes: String, maximum: Double, margin: Double, status: RollingWitnessEntryStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.notes = notes
            self.maximum = maximum
            self.margin = margin
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

        func canMoveTo(_ next: RollingWitnessEntryStatus) -> Bool {
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
                return next == RollingWitnessEntryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingWitnessEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling witness entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((margin + maximum) * 100).rounded() / 100
        }

        func copyValue() -> RollingWitnessEntry {
            return RollingWitnessEntry(
                code: code,
                name: name,
                approved: approved,
                notes: notes,
                maximum: maximum,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling witness entry in status requested.
    static func newRollingWitnessEntry(_ code: String, name: String) -> RollingWitnessEntry {
        return RollingWitnessEntry(
            code: code,
            name: name,
            approved: false,
            notes: "",
            maximum: 0.0,
            margin: 0.0,
            status: RollingWitnessEntryStatus.requested
        )
    }
}
