import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default substitution tier is in its life cycle.
    enum DefaultSubstitutionTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default substitution tier as the substitution team keeps it.
    final class DefaultSubstitutionTier {
        var code: String
        var name: String
        var weight: Double
        var active: Bool
        var allergy: String
        var retries: Int
        var payer: String
        var dosageMg: Double
        var category: String
        var source: String
        var version: Int
        var status: DefaultSubstitutionTierStatus

        init(code: String, name: String, weight: Double, active: Bool, allergy: String, retries: Int, payer: String, dosageMg: Double, category: String, source: String, version: Int, status: DefaultSubstitutionTierStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.active = active
            self.allergy = allergy
            self.retries = retries
            self.payer = payer
            self.dosageMg = dosageMg
            self.category = category
            self.source = source
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultSubstitutionTierStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultSubstitutionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default substitution tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("default substitution tier") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(version) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSubstitutionTier {
            return DefaultSubstitutionTier(
                code: code,
                name: name,
                weight: weight,
                active: active,
                allergy: allergy,
                retries: retries,
                payer: payer,
                dosageMg: dosageMg,
                category: category,
                source: source,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default substitution tier in status idle.
    static func newDefaultSubstitutionTier(_ code: String, name: String) -> DefaultSubstitutionTier {
        return DefaultSubstitutionTier(
            code: code,
            name: name,
            weight: 0.0,
            active: false,
            allergy: "",
            retries: 0,
            payer: "",
            dosageMg: 0.0,
            category: "",
            source: "",
            version: 0,
            status: DefaultSubstitutionTierStatus.idle
        )
    }
}
