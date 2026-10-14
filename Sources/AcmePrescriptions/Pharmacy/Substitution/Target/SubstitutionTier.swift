import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution tier is in its life cycle.
    enum SubstitutionTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A substitution tier as the substitution team keeps it.
    final class SubstitutionTier {
        var code: String
        var title: String
        var allergy: String
        var discount: Double
        var expiresAt: Int
        var label: String
        var ward: String
        var tags: [String]
        var specialty: String
        var region: String
        var reviewer: String
        var status: SubstitutionTierStatus

        init(code: String, title: String, allergy: String, discount: Double, expiresAt: Int, label: String, ward: String, tags: [String], specialty: String, region: String, reviewer: String, status: SubstitutionTierStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.discount = discount
            self.expiresAt = expiresAt
            self.label = label
            self.ward = ward
            self.tags = tags
            self.specialty = specialty
            self.region = region
            self.reviewer = reviewer
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

        func canMoveTo(_ next: SubstitutionTierStatus) -> Bool {
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
                return next == SubstitutionTierStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("substitution tier") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((Double(expiresAt) + discount) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionTier {
            return SubstitutionTier(
                code: code,
                title: title,
                allergy: allergy,
                discount: discount,
                expiresAt: expiresAt,
                label: label,
                ward: ward,
                tags: tags,
                specialty: specialty,
                region: region,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a substitution tier in status proposed.
    static func newSubstitutionTier(_ code: String, title: String) -> SubstitutionTier {
        return SubstitutionTier(
            code: code,
            title: title,
            allergy: "",
            discount: 0.0,
            expiresAt: 0,
            label: "",
            ward: "",
            tags: [],
            specialty: "",
            region: "",
            reviewer: "",
            status: SubstitutionTierStatus.proposed
        )
    }
}
