import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted remittance group is in its life cycle.
    enum WeightedRemittanceGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted remittance group as the remittance team keeps it.
    final class WeightedRemittanceGroup {
        var code: String
        var label: String
        var ratio: Double
        var allergy: String
        var attributes: [String: String]
        var country: String
        var status: WeightedRemittanceGroupStatus

        init(code: String, label: String, ratio: Double, allergy: String, attributes: [String: String], country: String, status: WeightedRemittanceGroupStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.allergy = allergy
            self.attributes = attributes
            self.country = country
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

        func canMoveTo(_ next: WeightedRemittanceGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedRemittanceGroupStatus.suspended
            case .pending:
                return next == WeightedRemittanceGroupStatus.active || next == WeightedRemittanceGroupStatus.suspended
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: WeightedRemittanceGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted remittance group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted remittance group") \(code)"
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

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> WeightedRemittanceGroup {
            return WeightedRemittanceGroup(
                code: code,
                label: label,
                ratio: ratio,
                allergy: allergy,
                attributes: attributes,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted remittance group in status draft.
    static func newWeightedRemittanceGroup(_ code: String, label: String) -> WeightedRemittanceGroup {
        return WeightedRemittanceGroup(
            code: code,
            label: label,
            ratio: 0.0,
            allergy: "",
            attributes: [:],
            country: "",
            status: WeightedRemittanceGroupStatus.draft
        )
    }
}
