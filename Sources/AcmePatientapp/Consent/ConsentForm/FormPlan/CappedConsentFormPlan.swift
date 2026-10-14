import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped consent form plan is in its life cycle.
    enum CappedConsentFormPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped consent form plan as the consent form team keeps it.
    final class CappedConsentFormPlan {
        var code: String
        var title: String
        var refills: Int
        var ratio: Double
        var attributes: [String: String]
        var allergy: String
        var country: String
        var maximum: Double
        var durationMinutes: Int
        var unit: String
        var status: CappedConsentFormPlanStatus

        init(code: String, title: String, refills: Int, ratio: Double, attributes: [String: String], allergy: String, country: String, maximum: Double, durationMinutes: Int, unit: String, status: CappedConsentFormPlanStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.ratio = ratio
            self.attributes = attributes
            self.allergy = allergy
            self.country = country
            self.maximum = maximum
            self.durationMinutes = durationMinutes
            self.unit = unit
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

        func canMoveTo(_ next: CappedConsentFormPlanStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedConsentFormPlanStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: CappedConsentFormPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped consent form plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
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

        func effectiveTotal() -> Double {
            return (ratio * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> CappedConsentFormPlan {
            return CappedConsentFormPlan(
                code: code,
                title: title,
                refills: refills,
                ratio: ratio,
                attributes: attributes,
                allergy: allergy,
                country: country,
                maximum: maximum,
                durationMinutes: durationMinutes,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped consent form plan in status draft.
    static func newCappedConsentFormPlan(_ code: String, title: String) -> CappedConsentFormPlan {
        return CappedConsentFormPlan(
            code: code,
            title: title,
            refills: 0,
            ratio: 0.0,
            attributes: [:],
            allergy: "",
            country: "",
            maximum: 0.0,
            durationMinutes: 0,
            unit: "",
            status: CappedConsentFormPlanStatus.draft
        )
    }
}
