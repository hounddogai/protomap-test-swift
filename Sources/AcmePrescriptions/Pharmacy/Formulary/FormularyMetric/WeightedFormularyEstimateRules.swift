import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted formulary estimate must pass. Check returns its problems, or none.
    protocol WeightedFormularyEstimateRule {
        func check(_ item: WeightedFormularyEstimate) -> [String]
    }

    final class WeightedFormularyEstimateRequiredLabelRule: WeightedFormularyEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyEstimateTagsLimitRule: WeightedFormularyEstimateRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: WeightedFormularyEstimate) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class WeightedFormularyEstimateCodeLengthRule: WeightedFormularyEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFormularyEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFormularyEstimateAllowedLabelRule: WeightedFormularyEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedFormularyEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted formulary estimate.
    final class WeightedFormularyEstimateValidator {
        var rules: [any WeightedFormularyEstimateRule]

        init(rules: [any WeightedFormularyEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFormularyEstimate) -> [String] {
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

        func requireValid(_ item: WeightedFormularyEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFormularyEstimate]) -> [String: [String]] {
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

    static func defaultWeightedFormularyEstimateValidator() -> WeightedFormularyEstimateValidator {
        return WeightedFormularyEstimateValidator(
            rules: [
                WeightedFormularyEstimateRequiredLabelRule(message: "weighted formulary estimate needs an entry"),
                WeightedFormularyEstimateTagsLimitRule(maxCount: 255, banned: []),
                WeightedFormularyEstimateCodeLengthRule(maxLength: 16),
                WeightedFormularyEstimateAllowedLabelRule(allowed: ["primary"]),
            ]
        )
    }
}
