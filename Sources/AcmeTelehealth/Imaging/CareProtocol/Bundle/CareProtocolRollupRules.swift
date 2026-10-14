import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol rollup must pass. Check returns its problems, or none.
    protocol CareProtocolRollupRule {
        func check(_ item: CareProtocolRollup) -> [String]
    }

    final class CareProtocolRollupRefillsRangeRule: CareProtocolRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolRollup) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolRollupWardLengthRule: CareProtocolRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolRollup) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolRollupNameLengthRule: CareProtocolRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolRollupRequiredNameRule: CareProtocolRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolRollupCodeLengthRule: CareProtocolRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol rollup.
    final class CareProtocolRollupValidator {
        var rules: [any CareProtocolRollupRule]

        init(rules: [any CareProtocolRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolRollup]) -> [String: [String]] {
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

    static func defaultCareProtocolRollupValidator() -> CareProtocolRollupValidator {
        return CareProtocolRollupValidator(
            rules: [
                CareProtocolRollupRefillsRangeRule(min: 3600, max: 86400),
                CareProtocolRollupWardLengthRule(maxLength: 1000),
                CareProtocolRollupNameLengthRule(maxLength: 86400),
                CareProtocolRollupRequiredNameRule(message: "care protocol rollup needs a value"),
                CareProtocolRollupCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
