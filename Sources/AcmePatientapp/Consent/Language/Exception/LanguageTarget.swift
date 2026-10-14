import AcmePlatform
import Foundation

extension Consent {
    /// Where a language target is in its life cycle.
    enum LanguageTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A language target. Its code is unique within a tenant.
    final class LanguageTarget {
        var code: String
        var label: String
        var procedureCode: String
        var encounterID: String
        var attributes: [String: String]
        var cost: Double
        var budget: Double
        var endsAt: Int
        var windowDays: Int
        var ratio: Double
        var status: LanguageTargetStatus

        init(code: String, label: String, procedureCode: String, encounterID: String, attributes: [String: String], cost: Double, budget: Double, endsAt: Int, windowDays: Int, ratio: Double, status: LanguageTargetStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.encounterID = encounterID
            self.attributes = attributes
            self.cost = cost
            self.budget = budget
            self.endsAt = endsAt
            self.windowDays = windowDays
            self.ratio = ratio
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

        func canMoveTo(_ next: LanguageTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == LanguageTargetStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LanguageTargetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
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

        func effectiveLoad() -> Double {
            return ((Double(endsAt) - cost) * 100).rounded() / 100
        }

        func copyValue() -> LanguageTarget {
            return LanguageTarget(
                code: code,
                label: label,
                procedureCode: procedureCode,
                encounterID: encounterID,
                attributes: attributes,
                cost: cost,
                budget: budget,
                endsAt: endsAt,
                windowDays: windowDays,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a language target in status created.
    static func newLanguageTarget(_ code: String, label: String) -> LanguageTarget {
        return LanguageTarget(
            code: code,
            label: label,
            procedureCode: "",
            encounterID: "",
            attributes: [:],
            cost: 0.0,
            budget: 0.0,
            endsAt: 0,
            windowDays: 0,
            ratio: 0.0,
            status: LanguageTargetStatus.created
        )
    }
}
