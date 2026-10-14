import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict authorization entry is in its life cycle.
    enum StrictAuthorizationEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a strict authorization entry and its current status.
    final class StrictAuthorizationEntry {
        var code: String
        var label: String
        var createdAt: Int
        var specialty: String
        var ownerID: String
        var allergy: String
        var status: StrictAuthorizationEntryStatus

        init(code: String, label: String, createdAt: Int, specialty: String, ownerID: String, allergy: String, status: StrictAuthorizationEntryStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.specialty = specialty
            self.ownerID = ownerID
            self.allergy = allergy
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

        func canMoveTo(_ next: StrictAuthorizationEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StrictAuthorizationEntryStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StrictAuthorizationEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict authorization entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> StrictAuthorizationEntry {
            return StrictAuthorizationEntry(
                code: code,
                label: label,
                createdAt: createdAt,
                specialty: specialty,
                ownerID: ownerID,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict authorization entry in status created.
    static func newStrictAuthorizationEntry(_ code: String, label: String) -> StrictAuthorizationEntry {
        return StrictAuthorizationEntry(
            code: code,
            label: label,
            createdAt: 0,
            specialty: "",
            ownerID: "",
            allergy: "",
            status: StrictAuthorizationEntryStatus.created
        )
    }
}
