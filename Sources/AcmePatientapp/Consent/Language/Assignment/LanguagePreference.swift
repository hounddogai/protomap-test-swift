import AcmePlatform
import Foundation

extension Consent {
    /// Where a language preference is in its life cycle.
    enum LanguagePreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One language preference, with what the planners need to act on it.
    final class LanguagePreference {
        var code: String
        var title: String
        var ceiling: Double
        var label: String
        var discount: Double
        var rate: Double
        var minimum: Double
        var description: String
        var status: LanguagePreferenceStatus

        init(code: String, title: String, ceiling: Double, label: String, discount: Double, rate: Double, minimum: Double, description: String, status: LanguagePreferenceStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.label = label
            self.discount = discount
            self.rate = rate
            self.minimum = minimum
            self.description = description
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

        func canMoveTo(_ next: LanguagePreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == LanguagePreferenceStatus.revoked || next == LanguagePreferenceStatus.expired
            case .granted:
                return next == LanguagePreferenceStatus.revoked || next == LanguagePreferenceStatus.expired
            case .revoked:
                return next == LanguagePreferenceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguagePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("language preference") \(code)"
        }

        func netVolume() -> Double {
            return (discount * ceiling * 100).rounded() / 100
        }

        func copyValue() -> LanguagePreference {
            return LanguagePreference(
                code: code,
                title: title,
                ceiling: ceiling,
                label: label,
                discount: discount,
                rate: rate,
                minimum: minimum,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a language preference in status requested.
    static func newLanguagePreference(_ code: String, title: String) -> LanguagePreference {
        return LanguagePreference(
            code: code,
            title: title,
            ceiling: 0.0,
            label: "",
            discount: 0.0,
            rate: 0.0,
            minimum: 0.0,
            description: "",
            status: LanguagePreferenceStatus.requested
        )
    }
}
