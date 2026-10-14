import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction profile is in its life cycle.
    enum InteractionProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One interaction profile, with what the planners need to act on it.
    final class InteractionProfile {
        var code: String
        var name: String
        var pinned: Bool
        var weight: Double
        var specialty: String
        var phone: String
        var unit: String
        var priority: Int
        var status: InteractionProfileStatus

        init(code: String, name: String, pinned: Bool, weight: Double, specialty: String, phone: String, unit: String, priority: Int, status: InteractionProfileStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.weight = weight
            self.specialty = specialty
            self.phone = phone
            self.unit = unit
            self.priority = priority
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

        func canMoveTo(_ next: InteractionProfileStatus) -> Bool {
            switch status {
            case .created:
                return next == InteractionProfileStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == InteractionProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("interaction profile") \(code)"
        }

        func projectedTotal() -> Double {
            return ((weight - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionProfile {
            return InteractionProfile(
                code: code,
                name: name,
                pinned: pinned,
                weight: weight,
                specialty: specialty,
                phone: phone,
                unit: unit,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a interaction profile in status created.
    static func newInteractionProfile(_ code: String, name: String) -> InteractionProfile {
        return InteractionProfile(
            code: code,
            name: name,
            pinned: false,
            weight: 0.0,
            specialty: "",
            phone: "",
            unit: "",
            priority: 0,
            status: InteractionProfileStatus.created
        )
    }
}
