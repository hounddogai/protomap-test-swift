import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist digest must pass. Check returns its problems, or none.
    protocol WorklistDigestRule {
        func check(_ item: WorklistDigest) -> [String]
    }

    final class WorklistDigestEndsAtRangeRule: WorklistDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistDigest) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistDigestRequiredCodeRule: WorklistDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistDigestRequiredTitleRule: WorklistDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistDigestAllowedTitleRule: WorklistDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class WorklistDigestCodeLengthRule: WorklistDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist digest.
    final class WorklistDigestValidator {
        var rules: [any WorklistDigestRule]

        init(rules: [any WorklistDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistDigest) -> [String] {
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

        func requireValid(_ item: WorklistDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistDigest]) -> [String: [String]] {
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

    static func defaultWorklistDigestValidator() -> WorklistDigestValidator {
        return WorklistDigestValidator(
            rules: [
                WorklistDigestEndsAtRangeRule(min: 64, max: 64),
                WorklistDigestRequiredCodeRule(message: "worklist digest needs a value"),
                WorklistDigestRequiredTitleRule(message: "worklist digest needs an entry"),
                WorklistDigestAllowedTitleRule(allowed: ["default"]),
                WorklistDigestCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
