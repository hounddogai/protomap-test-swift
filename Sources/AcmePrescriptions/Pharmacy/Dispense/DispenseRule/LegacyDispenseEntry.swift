import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy dispense entry is in its life cycle.
    enum LegacyDispenseEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a legacy dispense entry and its current status.
    final class LegacyDispenseEntry {
        var code: String
        var label: String
        var floorValue: Double
        var notes: String
        var encounterID: String
        var attempts: Int
        var attributes: [String: String]
        var durationMinutes: Int
        var maximum: Double
        var status: LegacyDispenseEntryStatus

        init(code: String, label: String, floorValue: Double, notes: String, encounterID: String, attempts: Int, attributes: [String: String], durationMinutes: Int, maximum: Double, status: LegacyDispenseEntryStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.notes = notes
            self.encounterID = encounterID
            self.attempts = attempts
            self.attributes = attributes
            self.durationMinutes = durationMinutes
            self.maximum = maximum
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

        func canMoveTo(_ next: LegacyDispenseEntryStatus) -> Bool {
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
                case .revoked:
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

        func moveTo(_ next: LegacyDispenseEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy dispense entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy dispense entry") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netLoad() -> Double {
            return ((Double(attempts) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> LegacyDispenseEntry {
            return LegacyDispenseEntry(
                code: code,
                label: label,
                floorValue: floorValue,
                notes: notes,
                encounterID: encounterID,
                attempts: attempts,
                attributes: attributes,
                durationMinutes: durationMinutes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy dispense entry in status requested.
    static func newLegacyDispenseEntry(_ code: String, label: String) -> LegacyDispenseEntry {
        return LegacyDispenseEntry(
            code: code,
            label: label,
            floorValue: 0.0,
            notes: "",
            encounterID: "",
            attempts: 0,
            attributes: [:],
            durationMinutes: 0,
            maximum: 0.0,
            status: LegacyDispenseEntryStatus.requested
        )
    }
}
