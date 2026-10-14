import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary plan is in its life cycle.
    enum FormularyPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A formulary plan as the formulary team keeps it.
    final class FormularyPlan {
        var code: String
        var label: String
        var attributes: [String: String]
        var channel: String
        var floorValue: Double
        var startsAt: Int
        var summary: String
        var status: FormularyPlanStatus

        init(code: String, label: String, attributes: [String: String], channel: String, floorValue: Double, startsAt: Int, summary: String, status: FormularyPlanStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.channel = channel
            self.floorValue = floorValue
            self.startsAt = startsAt
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyPlanStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: FormularyPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func netValue() -> Double {
            return ((Double(startsAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FormularyPlan {
            return FormularyPlan(
                code: code,
                label: label,
                attributes: attributes,
                channel: channel,
                floorValue: floorValue,
                startsAt: startsAt,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a formulary plan in status created.
    static func newFormularyPlan(_ code: String, label: String) -> FormularyPlan {
        return FormularyPlan(
            code: code,
            label: label,
            attributes: [:],
            channel: "",
            floorValue: 0.0,
            startsAt: 0,
            summary: "",
            status: FormularyPlanStatus.created
        )
    }
}
