import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive rounding preference is in its life cycle.
    enum AdaptiveRoundingPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One adaptive rounding preference, with what the planners need to act on it.
    final class AdaptiveRoundingPreference {
        var code: String
        var label: String
        var summary: String
        var ownerID: String
        var durationMinutes: Int
        var currency: String
        var contactEmail: String
        var name: String
        var locale: String
        var status: AdaptiveRoundingPreferenceStatus

        init(code: String, label: String, summary: String, ownerID: String, durationMinutes: Int, currency: String, contactEmail: String, name: String, locale: String, status: AdaptiveRoundingPreferenceStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.ownerID = ownerID
            self.durationMinutes = durationMinutes
            self.currency = currency
            self.contactEmail = contactEmail
            self.name = name
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveRoundingPreferenceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AdaptiveRoundingPreferenceStatus.running || next == AdaptiveRoundingPreferenceStatus.done
            case .running:
                return next == AdaptiveRoundingPreferenceStatus.done || next == AdaptiveRoundingPreferenceStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveRoundingPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive rounding preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> AdaptiveRoundingPreference {
            return AdaptiveRoundingPreference(
                code: code,
                label: label,
                summary: summary,
                ownerID: ownerID,
                durationMinutes: durationMinutes,
                currency: currency,
                contactEmail: contactEmail,
                name: name,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive rounding preference in status new.
    static func newAdaptiveRoundingPreference(_ code: String, label: String) -> AdaptiveRoundingPreference {
        return AdaptiveRoundingPreference(
            code: code,
            label: label,
            summary: "",
            ownerID: "",
            durationMinutes: 0,
            currency: "",
            contactEmail: "",
            name: "",
            locale: "",
            status: AdaptiveRoundingPreferenceStatus.new
        )
    }
}
