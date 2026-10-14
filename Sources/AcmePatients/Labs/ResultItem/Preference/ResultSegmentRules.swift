import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result segment must pass. Check returns its problems, or none.
    protocol ResultSegmentRule {
        func check(_ item: ResultSegment) -> [String]
    }

    final class ResultSegmentMarginRangeRule: ResultSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultSegment) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultSegmentRequiredLabelRule: ResultSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultSegmentRequiredCodeRule: ResultSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultSegmentActiveGuardRule: ResultSegmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ResultSegment) -> [String] {
            if item.active && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ResultSegmentAllowedLabelRule: ResultSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a result segment.
    final class ResultSegmentValidator {
        var rules: [any ResultSegmentRule]

        init(rules: [any ResultSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultSegment) -> [String] {
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

        func requireValid(_ item: ResultSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultSegment]) -> [String: [String]] {
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

    static func defaultResultSegmentValidator() -> ResultSegmentValidator {
        return ResultSegmentValidator(
            rules: [
                ResultSegmentMarginRangeRule(min: 6.6, max: 323.2),
                ResultSegmentRequiredLabelRule(message: "result segment needs this field"),
                ResultSegmentRequiredCodeRule(message: "result segment needs this field"),
                ResultSegmentActiveGuardRule(limit: 5.7),
                ResultSegmentAllowedLabelRule(allowed: ["primary", "batched"]),
            ]
        )
    }
}
