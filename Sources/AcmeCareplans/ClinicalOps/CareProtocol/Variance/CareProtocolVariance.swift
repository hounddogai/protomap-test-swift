import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol variance is in its life cycle.
    enum CareProtocolVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A care protocol variance as the care protocol team keeps it.
    final class CareProtocolVariance {
        var code: String
        var name: String
        var capacity: Int
        var locale: String
        var expiresAt: Int
        var floorValue: Double
        var budget: Double
        var specialty: String
        var status: CareProtocolVarianceStatus

        init(code: String, name: String, capacity: Int, locale: String, expiresAt: Int, floorValue: Double, budget: Double, specialty: String, status: CareProtocolVarianceStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.locale = locale
            self.expiresAt = expiresAt
            self.floorValue = floorValue
            self.budget = budget
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

        func canMoveTo(_ next: CareProtocolVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CareProtocolVarianceStatus.approved || next == CareProtocolVarianceStatus.withdrawn
            case .approved:
                return next == CareProtocolVarianceStatus.withdrawn
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

        func moveTo(_ next: CareProtocolVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("care protocol variance") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolVariance {
            return CareProtocolVariance(
                code: code,
                name: name,
                capacity: capacity,
                locale: locale,
                expiresAt: expiresAt,
                floorValue: floorValue,
                budget: budget,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a care protocol variance in status proposed.
    static func newCareProtocolVariance(_ code: String, name: String) -> CareProtocolVariance {
        return CareProtocolVariance(
            code: code,
            name: name,
            capacity: 0,
            locale: "",
            expiresAt: 0,
            floorValue: 0.0,
            budget: 0.0,
            specialty: "",
            status: CareProtocolVarianceStatus.proposed
        )
    }
}
