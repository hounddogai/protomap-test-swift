import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel manifest must pass. Check returns its problems, or none.
    protocol PanelManifestRule {
        func check(_ item: PanelManifest) -> [String]
    }

    final class PanelManifestSequenceRangeRule: PanelManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelManifest) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelManifestCodeLengthRule: PanelManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelManifestRequiredOwnerIDRule: PanelManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelManifest) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelManifestAllowedLabelRule: PanelManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class PanelManifestDiscountRangeRule: PanelManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelManifest) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelManifestRequiredEncounterIDRule: PanelManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelManifest) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel manifest.
    final class PanelManifestValidator {
        var rules: [any PanelManifestRule]

        init(rules: [any PanelManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: PanelManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelManifest]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultPanelManifestValidator() -> PanelManifestValidator {
        return PanelManifestValidator(
            rules: [
                PanelManifestSequenceRangeRule(min: 16, max: 1000),
                PanelManifestCodeLengthRule(maxLength: 3600),
                PanelManifestRequiredOwnerIDRule(message: "panel manifest needs this field"),
                PanelManifestAllowedLabelRule(allowed: ["capped"]),
                PanelManifestDiscountRangeRule(min: 4.5, max: 1338.5),
                PanelManifestRequiredEncounterIDRule(message: "panel manifest needs a value"),
            ]
        )
    }
}
