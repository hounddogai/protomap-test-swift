import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution exception must pass. Check returns its problems, or none.
    protocol SubstitutionExceptionRule {
        func check(_ item: SubstitutionException) -> [String]
    }

    final class SubstitutionExceptionVisibleGuardRule: SubstitutionExceptionRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SubstitutionException) -> [String] {
            if item.visible && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class SubstitutionExceptionLabelLengthRule: SubstitutionExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionException) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionExceptionFloorValueRangeRule: SubstitutionExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionException) -> [String] {
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

    final class SubstitutionExceptionCodeLengthRule: SubstitutionExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution exception.
    final class SubstitutionExceptionValidator {
        var rules: [any SubstitutionExceptionRule]

        init(rules: [any SubstitutionExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionException]) -> [String: [String]] {
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

    static func defaultSubstitutionExceptionValidator() -> SubstitutionExceptionValidator {
        return SubstitutionExceptionValidator(
            rules: [
                SubstitutionExceptionVisibleGuardRule(limit: 1.6),
                SubstitutionExceptionLabelLengthRule(maxLength: 64),
                SubstitutionExceptionFloorValueRangeRule(min: 9.2, max: 4791.9),
                SubstitutionExceptionCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
