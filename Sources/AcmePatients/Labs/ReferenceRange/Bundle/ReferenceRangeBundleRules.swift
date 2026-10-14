import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range bundle must pass. Check returns its problems, or none.
    protocol ReferenceRangeBundleRule {
        func check(_ item: ReferenceRangeBundle) -> [String]
    }

    final class ReferenceRangeBundleCodeLengthRule: ReferenceRangeBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeBundleLimitRangeRule: ReferenceRangeBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeBundle) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeBundleLabelLengthRule: ReferenceRangeBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range bundle.
    final class ReferenceRangeBundleValidator {
        var rules: [any ReferenceRangeBundleRule]

        init(rules: [any ReferenceRangeBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeBundle]) -> [String: [String]] {
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

    static func defaultReferenceRangeBundleValidator() -> ReferenceRangeBundleValidator {
        return ReferenceRangeBundleValidator(
            rules: [
                ReferenceRangeBundleCodeLengthRule(maxLength: 3600),
                ReferenceRangeBundleLimitRangeRule(min: 80, max: 120),
                ReferenceRangeBundleLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
