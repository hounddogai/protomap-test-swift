import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped overtime rollup must pass. Check returns its problems, or none.
    protocol CappedOvertimeRollupRule {
        func check(_ item: CappedOvertimeRollup) -> [String]
    }

    final class CappedOvertimeRollupAllowedExternalRefRule: CappedOvertimeRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedOvertimeRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is out of range"]
            }
            return []
        }
    }

    final class CappedOvertimeRollupNameLengthRule: CappedOvertimeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOvertimeRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOvertimeRollupRequiredChecksumRule: CappedOvertimeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedOvertimeRollup) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedOvertimeRollupRequiredNameRule: CappedOvertimeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedOvertimeRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped overtime rollup.
    final class CappedOvertimeRollupValidator {
        var rules: [any CappedOvertimeRollupRule]

        init(rules: [any CappedOvertimeRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedOvertimeRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedOvertimeRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedOvertimeRollup]) -> [String: [String]] {
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

    static func defaultCappedOvertimeRollupValidator() -> CappedOvertimeRollupValidator {
        return CappedOvertimeRollupValidator(
            rules: [
                CappedOvertimeRollupAllowedExternalRefRule(allowed: ["global", "weighted"]),
                CappedOvertimeRollupNameLengthRule(maxLength: 255),
                CappedOvertimeRollupRequiredChecksumRule(message: "capped overtime rollup needs a value"),
                CappedOvertimeRollupRequiredNameRule(message: "capped overtime rollup needs a value"),
            ]
        )
    }
}
