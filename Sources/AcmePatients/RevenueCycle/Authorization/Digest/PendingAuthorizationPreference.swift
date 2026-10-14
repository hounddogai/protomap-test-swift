import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending authorization preference is in its life cycle.
    enum PendingAuthorizationPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending authorization preference as the authorization team keeps it.
    final class PendingAuthorizationPreference {
        var code: String
        var label: String
        var specialty: String
        var ceiling: Double
        var rate: Double
        var category: String
        var country: String
        var minimum: Double
        var amount: Double
        var unit: String
        var retries: Int
        var status: PendingAuthorizationPreferenceStatus

        init(code: String, label: String, specialty: String, ceiling: Double, rate: Double, category: String, country: String, minimum: Double, amount: Double, unit: String, retries: Int, status: PendingAuthorizationPreferenceStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.ceiling = ceiling
            self.rate = rate
            self.category = category
            self.country = country
            self.minimum = minimum
            self.amount = amount
            self.unit = unit
            self.retries = retries
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

        func canMoveTo(_ next: PendingAuthorizationPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingAuthorizationPreferenceStatus.pending
            case .pending:
                return next == PendingAuthorizationPreferenceStatus.active || next == PendingAuthorizationPreferenceStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PendingAuthorizationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending authorization preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return (amount * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> PendingAuthorizationPreference {
            return PendingAuthorizationPreference(
                code: code,
                label: label,
                specialty: specialty,
                ceiling: ceiling,
                rate: rate,
                category: category,
                country: country,
                minimum: minimum,
                amount: amount,
                unit: unit,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending authorization preference in status draft.
    static func newPendingAuthorizationPreference(_ code: String, label: String) -> PendingAuthorizationPreference {
        return PendingAuthorizationPreference(
            code: code,
            label: label,
            specialty: "",
            ceiling: 0.0,
            rate: 0.0,
            category: "",
            country: "",
            minimum: 0.0,
            amount: 0.0,
            unit: "",
            retries: 0,
            status: PendingAuthorizationPreferenceStatus.draft
        )
    }
}
