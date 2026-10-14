import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier draft is in its life cycle.
    enum CourierDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One courier draft, with what the planners need to act on it.
    final class CourierDraft {
        var code: String
        var name: String
        var maximum: Double
        var country: String
        var unit: String
        var startsAt: Int
        var weight: Double
        var notes: String
        var channel: String
        var specialty: String
        var status: CourierDraftStatus

        init(code: String, name: String, maximum: Double, country: String, unit: String, startsAt: Int, weight: Double, notes: String, channel: String, specialty: String, status: CourierDraftStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.country = country
            self.unit = unit
            self.startsAt = startsAt
            self.weight = weight
            self.notes = notes
            self.channel = channel
            self.specialty = specialty
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

        func canMoveTo(_ next: CourierDraftStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CourierDraftStatus.rejected
            case .rejected:
                return next == CourierDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(startsAt) - weight) * 100).rounded() / 100
        }

        func copyValue() -> CourierDraft {
            return CourierDraft(
                code: code,
                name: name,
                maximum: maximum,
                country: country,
                unit: unit,
                startsAt: startsAt,
                weight: weight,
                notes: notes,
                channel: channel,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a courier draft in status proposed.
    static func newCourierDraft(_ code: String, name: String) -> CourierDraft {
        return CourierDraft(
            code: code,
            name: name,
            maximum: 0.0,
            country: "",
            unit: "",
            startsAt: 0,
            weight: 0.0,
            notes: "",
            channel: "",
            specialty: "",
            status: CourierDraftStatus.proposed
        )
    }
}
