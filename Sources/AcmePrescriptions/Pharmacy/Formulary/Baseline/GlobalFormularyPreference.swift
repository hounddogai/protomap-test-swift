import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global formulary preference is in its life cycle.
    enum GlobalFormularyPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a global formulary preference and its current status.
    final class GlobalFormularyPreference {
        var code: String
        var label: String
        var category: String
        var facility: String
        var ward: String
        var payer: String
        var refills: Int
        var attempts: Int
        var country: String
        var attributes: [String: String]
        var status: GlobalFormularyPreferenceStatus

        init(code: String, label: String, category: String, facility: String, ward: String, payer: String, refills: Int, attempts: Int, country: String, attributes: [String: String], status: GlobalFormularyPreferenceStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.facility = facility
            self.ward = ward
            self.payer = payer
            self.refills = refills
            self.attempts = attempts
            self.country = country
            self.attributes = attributes
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

        func canMoveTo(_ next: GlobalFormularyPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalFormularyPreferenceStatus.cancelled
            case .completed:
                return next == GlobalFormularyPreferenceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalFormularyPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global formulary preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global formulary preference") \(code)"
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
            return (Double(attempts) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFormularyPreference {
            return GlobalFormularyPreference(
                code: code,
                label: label,
                category: category,
                facility: facility,
                ward: ward,
                payer: payer,
                refills: refills,
                attempts: attempts,
                country: country,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global formulary preference in status planned.
    static func newGlobalFormularyPreference(_ code: String, label: String) -> GlobalFormularyPreference {
        return GlobalFormularyPreference(
            code: code,
            label: label,
            category: "",
            facility: "",
            ward: "",
            payer: "",
            refills: 0,
            attempts: 0,
            country: "",
            attributes: [:],
            status: GlobalFormularyPreferenceStatus.planned
        )
    }
}
