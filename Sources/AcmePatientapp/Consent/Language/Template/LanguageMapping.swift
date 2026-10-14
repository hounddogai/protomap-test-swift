import AcmePlatform
import Foundation

extension Consent {
    /// Where a language mapping is in its life cycle.
    enum LanguageMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a language mapping and its current status.
    final class LanguageMapping {
        var code: String
        var label: String
        var discount: Double
        var createdAt: Int
        var startsAt: Int
        var ceiling: Double
        var timezone: String
        var quantity: Int
        var summary: String
        var payer: String
        var status: LanguageMappingStatus

        init(code: String, label: String, discount: Double, createdAt: Int, startsAt: Int, ceiling: Double, timezone: String, quantity: Int, summary: String, payer: String, status: LanguageMappingStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.timezone = timezone
            self.quantity = quantity
            self.summary = summary
            self.payer = payer
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

        func canMoveTo(_ next: LanguageMappingStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LanguageMappingStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("language mapping") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(quantity) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageMapping {
            return LanguageMapping(
                code: code,
                label: label,
                discount: discount,
                createdAt: createdAt,
                startsAt: startsAt,
                ceiling: ceiling,
                timezone: timezone,
                quantity: quantity,
                summary: summary,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a language mapping in status requested.
    static func newLanguageMapping(_ code: String, label: String) -> LanguageMapping {
        return LanguageMapping(
            code: code,
            label: label,
            discount: 0.0,
            createdAt: 0,
            startsAt: 0,
            ceiling: 0.0,
            timezone: "",
            quantity: 0,
            summary: "",
            payer: "",
            status: LanguageMappingStatus.requested
        )
    }
}
