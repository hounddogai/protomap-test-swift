import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback network schedule is in its life cycle.
    enum FallbackNetworkScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a fallback network schedule and its current status.
    final class FallbackNetworkSchedule {
        var code: String
        var name: String
        var country: String
        var minimum: Double
        var endsAt: Int
        var priority: Int
        var discount: Double
        var acuity: Int
        var updatedAt: Int
        var contactEmail: String
        var version: Int
        var status: FallbackNetworkScheduleStatus

        init(code: String, name: String, country: String, minimum: Double, endsAt: Int, priority: Int, discount: Double, acuity: Int, updatedAt: Int, contactEmail: String, version: Int, status: FallbackNetworkScheduleStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.minimum = minimum
            self.endsAt = endsAt
            self.priority = priority
            self.discount = discount
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.contactEmail = contactEmail
            self.version = version
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

        func canMoveTo(_ next: FallbackNetworkScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackNetworkScheduleStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: FallbackNetworkScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback network schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedVolume() -> Double {
            return (minimum * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> FallbackNetworkSchedule {
            return FallbackNetworkSchedule(
                code: code,
                name: name,
                country: country,
                minimum: minimum,
                endsAt: endsAt,
                priority: priority,
                discount: discount,
                acuity: acuity,
                updatedAt: updatedAt,
                contactEmail: contactEmail,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback network schedule in status proposed.
    static func newFallbackNetworkSchedule(_ code: String, name: String) -> FallbackNetworkSchedule {
        return FallbackNetworkSchedule(
            code: code,
            name: name,
            country: "",
            minimum: 0.0,
            endsAt: 0,
            priority: 0,
            discount: 0.0,
            acuity: 0,
            updatedAt: 0,
            contactEmail: "",
            version: 0,
            status: FallbackNetworkScheduleStatus.proposed
        )
    }
}
