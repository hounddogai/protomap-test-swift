import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness entry is in its life cycle.
    enum WitnessEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a witness entry and its current status.
    final class WitnessEntry {
        var code: String
        var name: String
        var revision: Int
        var refills: Int
        var visitMinutes: Int
        var floorValue: Double
        var timezone: String
        var windowDays: Int
        var status: WitnessEntryStatus

        init(code: String, name: String, revision: Int, refills: Int, visitMinutes: Int, floorValue: Double, timezone: String, windowDays: Int, status: WitnessEntryStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.refills = refills
            self.visitMinutes = visitMinutes
            self.floorValue = floorValue
            self.timezone = timezone
            self.windowDays = windowDays
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

        func canMoveTo(_ next: WitnessEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == WitnessEntryStatus.revoked || next == WitnessEntryStatus.expired
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: WitnessEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return (Double(revision) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> WitnessEntry {
            return WitnessEntry(
                code: code,
                name: name,
                revision: revision,
                refills: refills,
                visitMinutes: visitMinutes,
                floorValue: floorValue,
                timezone: timezone,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a witness entry in status requested.
    static func newWitnessEntry(_ code: String, name: String) -> WitnessEntry {
        return WitnessEntry(
            code: code,
            name: name,
            revision: 0,
            refills: 0,
            visitMinutes: 0,
            floorValue: 0.0,
            timezone: "",
            windowDays: 0,
            status: WitnessEntryStatus.requested
        )
    }
}
