import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol rollup must pass. Check returns its problems, or none.
    protocol CareProtocolRollupRule {
        func check(_ item: CareProtocolRollup) -> [String]
    }

    final class CareProtocolRollupRequiredSourceRule: CareProtocolRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolRollup) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolRollupStartsAtRangeRule: CareProtocolRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolRollup) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolRollupAllowedSourceRule: CareProtocolRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is expired"]
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
                CareProtocolRollupRequiredSourceRule(message: "care protocol rollup needs a value"),
                CareProtocolRollupStartsAtRangeRule(min: 16, max: 3600),
                CareProtocolRollupAllowedSourceRule(allowed: []),
                CareProtocolRollupRequiredNameRule(message: "care protocol rollup needs this field"),
                CareProtocolRollupCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
