import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board metric must pass. Check returns its problems, or none.
    protocol BedBoardMetricRule {
        func check(_ item: BedBoardMetric) -> [String]
    }

    final class BedBoardMetricAllowedDiagnosisCodeRule: BedBoardMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is stale"]
            }
            return []
        }
    }

    final class BedBoardMetricVisibleGuardRule: BedBoardMetricRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BedBoardMetric) -> [String] {
            if item.visible && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class BedBoardMetricRequiredNameRule: BedBoardMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardMetricUpdatedAtRangeRule: BedBoardMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardMetric) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board metric.
    final class BedBoardMetricValidator {
        var rules: [any BedBoardMetricRule]

        init(rules: [any BedBoardMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardMetric]) -> [String: [String]] {
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

    static func defaultBedBoardMetricValidator() -> BedBoardMetricValidator {
        return BedBoardMetricValidator(
            rules: [
                BedBoardMetricAllowedDiagnosisCodeRule(allowed: ["manual"]),
                BedBoardMetricVisibleGuardRule(limit: 8.2),
                BedBoardMetricRequiredNameRule(message: "bed board metric needs this field"),
                BedBoardMetricUpdatedAtRangeRule(min: 64, max: 80),
            ]
        )
    }
}
