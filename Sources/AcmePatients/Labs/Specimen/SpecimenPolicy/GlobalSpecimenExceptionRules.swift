import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global specimen exception must pass. Check returns its problems, or none.
    protocol GlobalSpecimenExceptionRule {
        func check(_ item: GlobalSpecimenException) -> [String]
    }

    final class GlobalSpecimenExceptionRequiredTitleRule: GlobalSpecimenExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSpecimenException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSpecimenExceptionCodeLengthRule: GlobalSpecimenExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSpecimenException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSpecimenExceptionRequiredCodeRule: GlobalSpecimenExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSpecimenException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSpecimenExceptionVersionRangeRule: GlobalSpecimenExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSpecimenException) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalSpecimenExceptionAllowedTitleRule: GlobalSpecimenExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalSpecimenException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class GlobalSpecimenExceptionArchivedGuardRule: GlobalSpecimenExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalSpecimenException) -> [String] {
            if item.archived && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a global specimen exception.
    final class GlobalSpecimenExceptionValidator {
        var rules: [any GlobalSpecimenExceptionRule]

        init(rules: [any GlobalSpecimenExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSpecimenException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSpecimenException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSpecimenException]) -> [String: [String]] {
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

    static func defaultGlobalSpecimenExceptionValidator() -> GlobalSpecimenExceptionValidator {
        return GlobalSpecimenExceptionValidator(
            rules: [
                GlobalSpecimenExceptionRequiredTitleRule(message: "global specimen exception needs a value"),
                GlobalSpecimenExceptionCodeLengthRule(maxLength: 120),
                GlobalSpecimenExceptionRequiredCodeRule(message: "global specimen exception needs this field"),
                GlobalSpecimenExceptionVersionRangeRule(min: 16, max: 120),
                GlobalSpecimenExceptionAllowedTitleRule(allowed: ["weighted", "lenient", "batched"]),
                GlobalSpecimenExceptionArchivedGuardRule(limit: 64),
            ]
        )
    }
}
