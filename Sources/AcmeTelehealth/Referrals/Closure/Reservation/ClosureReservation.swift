import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure reservation is in its life cycle.
    enum ClosureReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A closure reservation as the closure team keeps it.
    final class ClosureReservation {
        var code: String
        var name: String
        var specialty: String
        var quantity: Int
        var description: String
        var revision: Int
        var tags: [String]
        var status: ClosureReservationStatus

        init(code: String, name: String, specialty: String, quantity: Int, description: String, revision: Int, tags: [String], status: ClosureReservationStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.quantity = quantity
            self.description = description
            self.revision = revision
            self.tags = tags
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

        func canMoveTo(_ next: ClosureReservationStatus) -> Bool {
            switch status {
            case .created:
                return next == ClosureReservationStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ClosureReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("closure reservation") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return (Double(revision) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> ClosureReservation {
            return ClosureReservation(
                code: code,
                name: name,
                specialty: specialty,
                quantity: quantity,
                description: description,
                revision: revision,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a closure reservation in status created.
    static func newClosureReservation(_ code: String, name: String) -> ClosureReservation {
        return ClosureReservation(
            code: code,
            name: name,
            specialty: "",
            quantity: 0,
            description: "",
            revision: 0,
            tags: [],
            status: ClosureReservationStatus.created
        )
    }
}
