import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution preference is in its life cycle.
    enum SubstitutionPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A substitution preference as the substitution team keeps it.
    final class SubstitutionPreference {
        var code: String
        var name: String
        var amount: Double
        var cost: Double
        var expiresAt: Int
        var checksum: String
        var weight: Double
        var category: String
        var status: SubstitutionPreferenceStatus

        init(code: String, name: String, amount: Double, cost: Double, expiresAt: Int, checksum: String, weight: Double, category: String, status: SubstitutionPreferenceStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.cost = cost
            self.expiresAt = expiresAt
            self.checksum = checksum
            self.weight = weight
            self.category = category
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

        func canMoveTo(_ next: SubstitutionPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SubstitutionPreferenceStatus.withdrawn
            case .approved:
                return next == SubstitutionPreferenceStatus.withdrawn
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

        func moveTo(_ next: SubstitutionPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("substitution preference") \(code)"
        }

        func netVolume() -> Double {
            return ((cost - amount) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionPreference {
            return SubstitutionPreference(
                code: code,
                name: name,
                amount: amount,
                cost: cost,
                expiresAt: expiresAt,
                checksum: checksum,
                weight: weight,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a substitution preference in status proposed.
    static func newSubstitutionPreference(_ code: String, name: String) -> SubstitutionPreference {
        return SubstitutionPreference(
            code: code,
            name: name,
            amount: 0.0,
            cost: 0.0,
            expiresAt: 0,
            checksum: "",
            weight: 0.0,
            category: "",
            status: SubstitutionPreferenceStatus.proposed
        )
    }
}
