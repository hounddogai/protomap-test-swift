import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted credential reservation is in its life cycle.
    enum WeightedCredentialReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted credential reservation. Its code is unique within a tenant.
    final class WeightedCredentialReservation {
        var code: String
        var title: String
        var specialty: String
        var maximum: Double
        var phone: String
        var archived: Bool
        var country: String
        var status: WeightedCredentialReservationStatus

        init(code: String, title: String, specialty: String, maximum: Double, phone: String, archived: Bool, country: String, status: WeightedCredentialReservationStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.maximum = maximum
            self.phone = phone
            self.archived = archived
            self.country = country
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

        func canMoveTo(_ next: WeightedCredentialReservationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WeightedCredentialReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted credential reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> WeightedCredentialReservation {
            return WeightedCredentialReservation(
                code: code,
                title: title,
                specialty: specialty,
                maximum: maximum,
                phone: phone,
                archived: archived,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted credential reservation in status proposed.
    static func newWeightedCredentialReservation(_ code: String, title: String) -> WeightedCredentialReservation {
        return WeightedCredentialReservation(
            code: code,
            title: title,
            specialty: "",
            maximum: 0.0,
            phone: "",
            archived: false,
            country: "",
            status: WeightedCredentialReservationStatus.proposed
        )
    }
}
