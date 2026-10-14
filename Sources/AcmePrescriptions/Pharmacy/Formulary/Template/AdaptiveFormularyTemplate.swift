import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive formulary template is in its life cycle.
    enum AdaptiveFormularyTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a adaptive formulary template and its current status.
    final class AdaptiveFormularyTemplate {
        var code: String
        var label: String
        var minimum: Double
        var approved: Bool
        var graceDays: Int
        var country: String
        var attributes: [String: String]
        var contactEmail: String
        var attempts: Int
        var status: AdaptiveFormularyTemplateStatus

        init(code: String, label: String, minimum: Double, approved: Bool, graceDays: Int, country: String, attributes: [String: String], contactEmail: String, attempts: Int, status: AdaptiveFormularyTemplateStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.approved = approved
            self.graceDays = graceDays
            self.country = country
            self.attributes = attributes
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveFormularyTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AdaptiveFormularyTemplateStatus.completed || next == AdaptiveFormularyTemplateStatus.cancelled
            case .completed:
                return next == AdaptiveFormularyTemplateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveFormularyTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive formulary template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive formulary template") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedVolume() -> Double {
            return (Double(graceDays) * minimum * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFormularyTemplate {
            return AdaptiveFormularyTemplate(
                code: code,
                label: label,
                minimum: minimum,
                approved: approved,
                graceDays: graceDays,
                country: country,
                attributes: attributes,
                contactEmail: contactEmail,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive formulary template in status planned.
    static func newAdaptiveFormularyTemplate(_ code: String, label: String) -> AdaptiveFormularyTemplate {
        return AdaptiveFormularyTemplate(
            code: code,
            label: label,
            minimum: 0.0,
            approved: false,
            graceDays: 0,
            country: "",
            attributes: [:],
            contactEmail: "",
            attempts: 0,
            status: AdaptiveFormularyTemplateStatus.planned
        )
    }
}
