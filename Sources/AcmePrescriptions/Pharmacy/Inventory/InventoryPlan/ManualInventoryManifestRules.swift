import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual inventory manifest must pass. Check returns its problems, or none.
    protocol ManualInventoryManifestRule {
        func check(_ item: ManualInventoryManifest) -> [String]
    }

    final class ManualInventoryManifestBedLengthRule: ManualInventoryManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualInventoryManifest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualInventoryManifestMinimumRangeRule: ManualInventoryManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualInventoryManifest) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualInventoryManifestLabelLengthRule: ManualInventoryManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualInventoryManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualInventoryManifestRequiredBedRule: ManualInventoryManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualInventoryManifest) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualInventoryManifestAllowedCodeRule: ManualInventoryManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualInventoryManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class ManualInventoryManifestRequiredLabelRule: ManualInventoryManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualInventoryManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual inventory manifest.
    final class ManualInventoryManifestValidator {
        var rules: [any ManualInventoryManifestRule]

        init(rules: [any ManualInventoryManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualInventoryManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualInventoryManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualInventoryManifest]) -> [String: [String]] {
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

    static func defaultManualInventoryManifestValidator() -> ManualInventoryManifestValidator {
        return ManualInventoryManifestValidator(
            rules: [
                ManualInventoryManifestBedLengthRule(maxLength: 86400),
                ManualInventoryManifestMinimumRangeRule(min: 2.3, max: 2786.7),
                ManualInventoryManifestLabelLengthRule(maxLength: 255),
                ManualInventoryManifestRequiredBedRule(message: "manual inventory manifest needs an entry"),
                ManualInventoryManifestAllowedCodeRule(allowed: ["rolling"]),
                ManualInventoryManifestRequiredLabelRule(message: "manual inventory manifest needs this field"),
            ]
        )
    }
}
