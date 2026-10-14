import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier digest must pass. Check returns its problems, or none.
    protocol CourierDigestRule {
        func check(_ item: CourierDigest) -> [String]
    }

    final class CourierDigestCodeLengthRule: CourierDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierDigestActiveGuardRule: CourierDigestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CourierDigest) -> [String] {
            if item.active && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class CourierDigestRequiredCategoryRule: CourierDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierDigest) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier digest.
    final class CourierDigestValidator {
        var rules: [any CourierDigestRule]

        init(rules: [any CourierDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierDigest]) -> [String: [String]] {
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

    static func defaultCourierDigestValidator() -> CourierDigestValidator {
        return CourierDigestValidator(
            rules: [
                CourierDigestCodeLengthRule(maxLength: 32),
                CourierDigestActiveGuardRule(limit: 9.0),
                CourierDigestRequiredCategoryRule(message: "courier digest needs this field"),
            ]
        )
    }
}
