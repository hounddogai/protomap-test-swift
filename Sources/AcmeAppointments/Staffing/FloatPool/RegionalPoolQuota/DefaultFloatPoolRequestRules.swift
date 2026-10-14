import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default float pool request must pass. Check returns its problems, or none.
    protocol DefaultFloatPoolRequestRule {
        func check(_ item: DefaultFloatPoolRequest) -> [String]
    }

    final class DefaultFloatPoolRequestRequiredCodeRule: DefaultFloatPoolRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFloatPoolRequestVisibleGuardRule: DefaultFloatPoolRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DefaultFloatPoolRequest) -> [String] {
            if item.visible && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class DefaultFloatPoolRequestSpecialtyLengthRule: DefaultFloatPoolRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolRequest) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default float pool request.
    final class DefaultFloatPoolRequestValidator {
        var rules: [any DefaultFloatPoolRequestRule]

        init(rules: [any DefaultFloatPoolRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFloatPoolRequest) -> [String] {
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

        func requireValid(_ item: DefaultFloatPoolRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFloatPoolRequest]) -> [String: [String]] {
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

    static func defaultDefaultFloatPoolRequestValidator() -> DefaultFloatPoolRequestValidator {
        return DefaultFloatPoolRequestValidator(
            rules: [
                DefaultFloatPoolRequestRequiredCodeRule(message: "default float pool request needs an entry"),
                DefaultFloatPoolRequestVisibleGuardRule(limit: 2.8),
                DefaultFloatPoolRequestSpecialtyLengthRule(maxLength: 1000),
            ]
        )
    }
}
