import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient courier group must pass. Check returns its problems, or none.
    protocol LenientCourierGroupRule {
        func check(_ item: LenientCourierGroup) -> [String]
    }

    final class LenientCourierGroupRequiredBedRule: LenientCourierGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCourierGroup) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCourierGroupRequiredCodeRule: LenientCourierGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCourierGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCourierGroupFloorValueRangeRule: LenientCourierGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCourierGroup) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientCourierGroupAllowedTitleRule: LenientCourierGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientCourierGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient courier group.
    final class LenientCourierGroupValidator {
        var rules: [any LenientCourierGroupRule]

        init(rules: [any LenientCourierGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCourierGroup) -> [String] {
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

        func requireValid(_ item: LenientCourierGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCourierGroup]) -> [String: [String]] {
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

    static func defaultLenientCourierGroupValidator() -> LenientCourierGroupValidator {
        return LenientCourierGroupValidator(
            rules: [
                LenientCourierGroupRequiredBedRule(message: "lenient courier group needs this field"),
                LenientCourierGroupRequiredCodeRule(message: "lenient courier group needs an entry"),
                LenientCourierGroupFloorValueRangeRule(min: 6.0, max: 3570.5),
                LenientCourierGroupAllowedTitleRule(allowed: []),
            ]
        )
    }
}
