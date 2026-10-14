import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict result preference is in its life cycle.
    enum StrictResultPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a strict result preference and its current status.
    final class StrictResultPreference {
        var code: String
        var title: String
        var capacity: Int
        var notes: String
        var contactEmail: String
        var endsAt: Int
        var active: Bool
        var score: Double
        var floorValue: Double
        var status: StrictResultPreferenceStatus

        init(code: String, title: String, capacity: Int, notes: String, contactEmail: String, endsAt: Int, active: Bool, score: Double, floorValue: Double, status: StrictResultPreferenceStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.notes = notes
            self.contactEmail = contactEmail
            self.endsAt = endsAt
            self.active = active
            self.score = score
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictResultPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictResultPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictResultPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict result preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((score + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictResultPreference {
            return StrictResultPreference(
                code: code,
                title: title,
                capacity: capacity,
                notes: notes,
                contactEmail: contactEmail,
                endsAt: endsAt,
                active: active,
                score: score,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict result preference in status draft.
    static func newStrictResultPreference(_ code: String, title: String) -> StrictResultPreference {
        return StrictResultPreference(
            code: code,
            title: title,
            capacity: 0,
            notes: "",
            contactEmail: "",
            endsAt: 0,
            active: false,
            score: 0.0,
            floorValue: 0.0,
            status: StrictResultPreferenceStatus.draft
        )
    }
}
