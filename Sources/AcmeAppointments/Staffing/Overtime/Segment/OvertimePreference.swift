import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime preference is in its life cycle.
    enum OvertimePreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One overtime preference, with what the planners need to act on it.
    final class OvertimePreference {
        var code: String
        var title: String
        var attributes: [String: String]
        var cost: Double
        var encounterID: String
        var pinned: Bool
        var graceDays: Int
        var allergy: String
        var minimum: Double
        var status: OvertimePreferenceStatus

        init(code: String, title: String, attributes: [String: String], cost: Double, encounterID: String, pinned: Bool, graceDays: Int, allergy: String, minimum: Double, status: OvertimePreferenceStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.cost = cost
            self.encounterID = encounterID
            self.pinned = pinned
            self.graceDays = graceDays
            self.allergy = allergy
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OvertimePreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == OvertimePreferenceStatus.rejected || next == OvertimePreferenceStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OvertimePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func adjustedExposure() -> Double {
            return ((cost + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimePreference {
            return OvertimePreference(
                code: code,
                title: title,
                attributes: attributes,
                cost: cost,
                encounterID: encounterID,
                pinned: pinned,
                graceDays: graceDays,
                allergy: allergy,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime preference in status proposed.
    static func newOvertimePreference(_ code: String, title: String) -> OvertimePreference {
        return OvertimePreference(
            code: code,
            title: title,
            attributes: [:],
            cost: 0.0,
            encounterID: "",
            pinned: false,
            graceDays: 0,
            allergy: "",
            minimum: 0.0,
            status: OvertimePreferenceStatus.proposed
        )
    }
}
