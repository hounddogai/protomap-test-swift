import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol override must pass. Check returns its problems, or none.
    protocol CareProtocolOverrideRule {
        func check(_ item: CareProtocolOverride) -> [String]
    }

    final class CareProtocolOverrideSpecialtyLengthRule: CareProtocolOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolOverride) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolOverrideWindowDaysRangeRule: CareProtocolOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolOverride) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolOverrideCodeLengthRule: CareProtocolOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol override.
    final class CareProtocolOverrideValidator {
        var rules: [any CareProtocolOverrideRule]

        init(rules: [any CareProtocolOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolOverride]) -> [String: [String]] {
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

    static func defaultCareProtocolOverrideValidator() -> CareProtocolOverrideValidator {
        return CareProtocolOverrideValidator(
            rules: [
                CareProtocolOverrideSpecialtyLengthRule(maxLength: 1000),
                CareProtocolOverrideWindowDaysRangeRule(min: 16, max: 120),
                CareProtocolOverrideCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
