import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted substitution rollup is in its life cycle.
    enum WeightedSubstitutionRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted substitution rollup. Its code is unique within a tenant.
    final class WeightedSubstitutionRollup {
        var code: String
        var title: String
        var retries: Int
        var windowDays: Int
        var notes: String
        var copay: Double
        var country: String
        var pinned: Bool
        var active: Bool
        var dosageMg: Double
        var status: WeightedSubstitutionRollupStatus

        init(code: String, title: String, retries: Int, windowDays: Int, notes: String, copay: Double, country: String, pinned: Bool, active: Bool, dosageMg: Double, status: WeightedSubstitutionRollupStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.windowDays = windowDays
            self.notes = notes
            self.copay = copay
            self.country = country
            self.pinned = pinned
            self.active = active
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedSubstitutionRollupStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedSubstitutionRollupStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: WeightedSubstitutionRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted substitution rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return (Double(retries) * copay * 100).rounded() / 100
        }

        func copyValue() -> WeightedSubstitutionRollup {
            return WeightedSubstitutionRollup(
                code: code,
                title: title,
                retries: retries,
                windowDays: windowDays,
                notes: notes,
                copay: copay,
                country: country,
                pinned: pinned,
                active: active,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted substitution rollup in status requested.
    static func newWeightedSubstitutionRollup(_ code: String, title: String) -> WeightedSubstitutionRollup {
        return WeightedSubstitutionRollup(
            code: code,
            title: title,
            retries: 0,
            windowDays: 0,
            notes: "",
            copay: 0.0,
            country: "",
            pinned: false,
            active: false,
            dosageMg: 0.0,
            status: WeightedSubstitutionRollupStatus.requested
        )
    }
}
