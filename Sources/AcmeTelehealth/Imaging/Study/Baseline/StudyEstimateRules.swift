import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study estimate must pass. Check returns its problems, or none.
    protocol StudyEstimateRule {
        func check(_ item: StudyEstimate) -> [String]
    }

    final class StudyEstimateFloorValueRangeRule: StudyEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyEstimate) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudyEstimateRefillsRangeRule: StudyEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyEstimate) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyEstimateCodePrefixRule: StudyEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a study estimate.
    final class StudyEstimateValidator {
        var rules: [any StudyEstimateRule]

        init(rules: [any StudyEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyEstimate) -> [String] {
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

        func requireValid(_ item: StudyEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyEstimate]) -> [String: [String]] {
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

    static func defaultStudyEstimateValidator() -> StudyEstimateValidator {
        return StudyEstimateValidator(
            rules: [
                StudyEstimateFloorValueRangeRule(min: 1.4, max: 3885.5),
                StudyEstimateRefillsRangeRule(min: 16, max: 3600),
                StudyEstimateCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
