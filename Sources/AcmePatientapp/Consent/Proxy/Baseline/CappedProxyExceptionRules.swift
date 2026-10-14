import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped proxy exception must pass. Check returns its problems, or none.
    protocol CappedProxyExceptionRule {
        func check(_ item: CappedProxyException) -> [String]
    }

    final class CappedProxyExceptionReviewerLengthRule: CappedProxyExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedProxyException) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedProxyExceptionRequiredReviewerRule: CappedProxyExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedProxyException) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedProxyExceptionNameLengthRule: CappedProxyExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedProxyException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedProxyExceptionCodeLengthRule: CappedProxyExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedProxyException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedProxyExceptionRequiredNameRule: CappedProxyExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedProxyException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedProxyExceptionVersionRangeRule: CappedProxyExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedProxyException) -> [String] {
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

    /// Runs every rule of a capped proxy exception.
    final class CappedProxyExceptionValidator {
        var rules: [any CappedProxyExceptionRule]

        init(rules: [any CappedProxyExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedProxyException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedProxyException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedProxyException]) -> [String: [String]] {
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

    static func defaultCappedProxyExceptionValidator() -> CappedProxyExceptionValidator {
        return CappedProxyExceptionValidator(
            rules: [
                CappedProxyExceptionReviewerLengthRule(maxLength: 3600),
                CappedProxyExceptionRequiredReviewerRule(message: "capped proxy exception needs an entry"),
                CappedProxyExceptionNameLengthRule(maxLength: 64),
                CappedProxyExceptionCodeLengthRule(maxLength: 32),
                CappedProxyExceptionRequiredNameRule(message: "capped proxy exception needs an entry"),
                CappedProxyExceptionVersionRangeRule(min: 16, max: 64),
            ]
        )
    }
}
