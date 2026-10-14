import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary bed board metric must pass. Check returns its problems, or none.
    protocol PrimaryBedBoardMetricRule {
        func check(_ item: PrimaryBedBoardMetric) -> [String]
    }

    final class PrimaryBedBoardMetricAllowedCategoryRule: PrimaryBedBoardMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryBedBoardMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is missing"]
            }
            return []
        }
    }

    final class PrimaryBedBoardMetricRequiredNameRule: PrimaryBedBoardMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryBedBoardMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryBedBoardMetricUpdatedAtRangeRule: PrimaryBedBoardMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryBedBoardMetric) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryBedBoardMetricRequiredCategoryRule: PrimaryBedBoardMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryBedBoardMetric) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary bed board metric.
    final class PrimaryBedBoardMetricValidator {
        var rules: [any PrimaryBedBoardMetricRule]

        init(rules: [any PrimaryBedBoardMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryBedBoardMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryBedBoardMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryBedBoardMetric]) -> [String: [String]] {
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

    static func defaultPrimaryBedBoardMetricValidator() -> PrimaryBedBoardMetricValidator {
        return PrimaryBedBoardMetricValidator(
            rules: [
                PrimaryBedBoardMetricAllowedCategoryRule(allowed: ["weighted", "lenient", "regional"]),
                PrimaryBedBoardMetricRequiredNameRule(message: "primary bed board metric needs this field"),
                PrimaryBedBoardMetricUpdatedAtRangeRule(min: 3600, max: 86400),
                PrimaryBedBoardMetricRequiredCategoryRule(message: "primary bed board metric needs an entry"),
            ]
        )
    }
}
