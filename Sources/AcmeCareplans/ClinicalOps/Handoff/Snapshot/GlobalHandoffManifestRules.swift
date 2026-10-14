import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global handoff manifest must pass. Check returns its problems, or none.
    protocol GlobalHandoffManifestRule {
        func check(_ item: GlobalHandoffManifest) -> [String]
    }

    final class GlobalHandoffManifestAmountRangeRule: GlobalHandoffManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalHandoffManifest) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalHandoffManifestRequiredCodeRule: GlobalHandoffManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalHandoffManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalHandoffManifestLabelLengthRule: GlobalHandoffManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalHandoffManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalHandoffManifestRequiredPatientRefRule: GlobalHandoffManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalHandoffManifest) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global handoff manifest.
    final class GlobalHandoffManifestValidator {
        var rules: [any GlobalHandoffManifestRule]

        init(rules: [any GlobalHandoffManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalHandoffManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalHandoffManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalHandoffManifest]) -> [String: [String]] {
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

    static func defaultGlobalHandoffManifestValidator() -> GlobalHandoffManifestValidator {
        return GlobalHandoffManifestValidator(
            rules: [
                GlobalHandoffManifestAmountRangeRule(min: 2.7, max: 3671.5),
                GlobalHandoffManifestRequiredCodeRule(message: "global handoff manifest needs a value"),
                GlobalHandoffManifestLabelLengthRule(maxLength: 255),
                GlobalHandoffManifestRequiredPatientRefRule(message: "global handoff manifest needs this field"),
            ]
        )
    }
}
