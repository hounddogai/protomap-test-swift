import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority preference is in its life cycle.
    enum PriorityPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a priority preference and its current status.
    final class PriorityPreference {
        var code: String
        var name: String
        var ward: String
        var rate: Double
        var payer: String
        var amount: Double
        var country: String
        var status: PriorityPreferenceStatus

        init(code: String, name: String, ward: String, rate: Double, payer: String, amount: Double, country: String, status: PriorityPreferenceStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.rate = rate
            self.payer = payer
            self.amount = amount
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

        func canMoveTo(_ next: PriorityPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PriorityPreferenceStatus.rejected
            case .approved:
                return next == PriorityPreferenceStatus.rejected || next == PriorityPreferenceStatus.withdrawn
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

        func moveTo(_ next: PriorityPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedExposure() -> Double {
            return (rate * amount * 100).rounded() / 100
        }

        func copyValue() -> PriorityPreference {
            return PriorityPreference(
                code: code,
                name: name,
                ward: ward,
                rate: rate,
                payer: payer,
                amount: amount,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a priority preference in status proposed.
    static func newPriorityPreference(_ code: String, name: String) -> PriorityPreference {
        return PriorityPreference(
            code: code,
            name: name,
            ward: "",
            rate: 0.0,
            payer: "",
            amount: 0.0,
            country: "",
            status: PriorityPreferenceStatus.proposed
        )
    }
}
