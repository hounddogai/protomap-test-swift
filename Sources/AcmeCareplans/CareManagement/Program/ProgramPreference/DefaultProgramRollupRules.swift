import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default program rollup must pass. Check returns its problems, or none.
    protocol DefaultProgramRollupRule {
        func check(_ item: DefaultProgramRollup) -> [String]
    }

    final class DefaultProgramRollupCodePrefixRule: DefaultProgramRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultProgramRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultProgramRollupLabelLengthRule: DefaultProgramRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultProgramRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultProgramRollupVisitMinutesRangeRule: DefaultProgramRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultProgramRollup) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultProgramRollupAllowedChecksumRule: DefaultProgramRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultProgramRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a default program rollup.
    final class DefaultProgramRollupValidator {
        var rules: [any DefaultProgramRollupRule]

        init(rules: [any DefaultProgramRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultProgramRollup) -> [String] {
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

        func requireValid(_ item: DefaultProgramRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultProgramRollup]) -> [String: [String]] {
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

    static func defaultDefaultProgramRollupValidator() -> DefaultProgramRollupValidator {
        return DefaultProgramRollupValidator(
            rules: [
                DefaultProgramRollupCodePrefixRule(prefix: "Q"),
                DefaultProgramRollupLabelLengthRule(maxLength: 64),
                DefaultProgramRollupVisitMinutesRangeRule(min: 64, max: 255),
                DefaultProgramRollupAllowedChecksumRule(allowed: []),
            ]
        )
    }
}
