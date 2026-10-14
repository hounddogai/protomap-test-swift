import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study template must pass. Check returns its problems, or none.
    protocol StudyTemplateRule {
        func check(_ item: StudyTemplate) -> [String]
    }

    final class StudyTemplateFloorValueRangeRule: StudyTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyTemplate) -> [String] {
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

    final class StudyTemplateStartsAtRangeRule: StudyTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyTemplate) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyTemplateWindowRule: StudyTemplateRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: StudyTemplate) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    final class StudyTemplateAllowedNameRule: StudyTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a study template.
    final class StudyTemplateValidator {
        var rules: [any StudyTemplateRule]

        init(rules: [any StudyTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyTemplate) -> [String] {
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

        func requireValid(_ item: StudyTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyTemplate]) -> [String: [String]] {
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

    static func defaultStudyTemplateValidator() -> StudyTemplateValidator {
        return StudyTemplateValidator(
            rules: [
                StudyTemplateFloorValueRangeRule(min: 8.1, max: 4127.7),
                StudyTemplateStartsAtRangeRule(min: 32, max: 1000),
                StudyTemplateWindowRule(maxSpan: 64),
                StudyTemplateAllowedNameRule(allowed: ["adaptive", "tiered", "capped"]),
            ]
        )
    }
}
