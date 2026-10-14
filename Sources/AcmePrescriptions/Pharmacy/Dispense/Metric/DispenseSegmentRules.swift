import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense segment must pass. Check returns its problems, or none.
    protocol DispenseSegmentRule {
        func check(_ item: DispenseSegment) -> [String]
    }

    final class DispenseSegmentAttemptsRangeRule: DispenseSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseSegment) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseSegmentAllowedLocaleRule: DispenseSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is missing"]
            }
            return []
        }
    }

    final class DispenseSegmentVisitMinutesRangeRule: DispenseSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseSegment) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseSegmentCodeLengthRule: DispenseSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense segment.
    final class DispenseSegmentValidator {
        var rules: [any DispenseSegmentRule]

        init(rules: [any DispenseSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseSegment) -> [String] {
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

        func requireValid(_ item: DispenseSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseSegment]) -> [String: [String]] {
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

    static func defaultDispenseSegmentValidator() -> DispenseSegmentValidator {
        return DispenseSegmentValidator(
            rules: [
                DispenseSegmentAttemptsRangeRule(min: 64, max: 86400),
                DispenseSegmentAllowedLocaleRule(allowed: ["strict", "fallback"]),
                DispenseSegmentVisitMinutesRangeRule(min: 80, max: 255),
                DispenseSegmentCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
