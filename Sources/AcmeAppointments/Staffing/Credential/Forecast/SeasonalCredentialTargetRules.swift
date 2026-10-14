import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal credential target must pass. Check returns its problems, or none.
    protocol SeasonalCredentialTargetRule {
        func check(_ item: SeasonalCredentialTarget) -> [String]
    }

    final class SeasonalCredentialTargetAllowedNameRule: SeasonalCredentialTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalCredentialTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class SeasonalCredentialTargetCodeLengthRule: SeasonalCredentialTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCredentialTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCredentialTargetRequiredCodeRule: SeasonalCredentialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCredentialTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCredentialTargetSequenceRangeRule: SeasonalCredentialTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCredentialTarget) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal credential target.
    final class SeasonalCredentialTargetValidator {
        var rules: [any SeasonalCredentialTargetRule]

        init(rules: [any SeasonalCredentialTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCredentialTarget) -> [String] {
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

        func requireValid(_ item: SeasonalCredentialTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCredentialTarget]) -> [String: [String]] {
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

    static func defaultSeasonalCredentialTargetValidator() -> SeasonalCredentialTargetValidator {
        return SeasonalCredentialTargetValidator(
            rules: [
                SeasonalCredentialTargetAllowedNameRule(allowed: ["adaptive", "strict"]),
                SeasonalCredentialTargetCodeLengthRule(maxLength: 32),
                SeasonalCredentialTargetRequiredCodeRule(message: "seasonal credential target needs an entry"),
                SeasonalCredentialTargetSequenceRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
