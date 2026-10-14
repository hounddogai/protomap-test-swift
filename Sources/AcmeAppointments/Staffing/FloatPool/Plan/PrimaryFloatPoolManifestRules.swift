import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary float pool manifest must pass. Check returns its problems, or none.
    protocol PrimaryFloatPoolManifestRule {
        func check(_ item: PrimaryFloatPoolManifest) -> [String]
    }

    final class PrimaryFloatPoolManifestRequiredLabelRule: PrimaryFloatPoolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryFloatPoolManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryFloatPoolManifestRequiredCodeRule: PrimaryFloatPoolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryFloatPoolManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryFloatPoolManifestLabelLengthRule: PrimaryFloatPoolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFloatPoolManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryFloatPoolManifestScoreRangeRule: PrimaryFloatPoolManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryFloatPoolManifest) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryFloatPoolManifestCostRangeRule: PrimaryFloatPoolManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryFloatPoolManifest) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary float pool manifest.
    final class PrimaryFloatPoolManifestValidator {
        var rules: [any PrimaryFloatPoolManifestRule]

        init(rules: [any PrimaryFloatPoolManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryFloatPoolManifest) -> [String] {
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

        func requireValid(_ item: PrimaryFloatPoolManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryFloatPoolManifest]) -> [String: [String]] {
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

    static func defaultPrimaryFloatPoolManifestValidator() -> PrimaryFloatPoolManifestValidator {
        return PrimaryFloatPoolManifestValidator(
            rules: [
                PrimaryFloatPoolManifestRequiredLabelRule(message: "primary float pool manifest needs this field"),
                PrimaryFloatPoolManifestRequiredCodeRule(message: "primary float pool manifest needs this field"),
                PrimaryFloatPoolManifestLabelLengthRule(maxLength: 86400),
                PrimaryFloatPoolManifestScoreRangeRule(min: 8.6, max: 2187.2),
                PrimaryFloatPoolManifestCostRangeRule(min: 8.5, max: 2986.0),
            ]
        )
    }
}
