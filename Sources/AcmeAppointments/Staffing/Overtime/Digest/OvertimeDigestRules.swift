import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime digest must pass. Check returns its problems, or none.
    protocol OvertimeDigestRule {
        func check(_ item: OvertimeDigest) -> [String]
    }

    final class OvertimeDigestCodeLengthRule: OvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeDigestRequiredTitleRule: OvertimeDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeDigestWardLengthRule: OvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeDigest) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeDigestAllowedCodeRule: OvertimeDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class OvertimeDigestSummaryLengthRule: OvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeDigest) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime digest.
    final class OvertimeDigestValidator {
        var rules: [any OvertimeDigestRule]

        init(rules: [any OvertimeDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeDigest) -> [String] {
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

        func requireValid(_ item: OvertimeDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeDigest]) -> [String: [String]] {
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

    static func defaultOvertimeDigestValidator() -> OvertimeDigestValidator {
        return OvertimeDigestValidator(
            rules: [
                OvertimeDigestCodeLengthRule(maxLength: 16),
                OvertimeDigestRequiredTitleRule(message: "overtime digest needs this field"),
                OvertimeDigestWardLengthRule(maxLength: 86400),
                OvertimeDigestAllowedCodeRule(allowed: ["lenient", "primary", "legacy"]),
                OvertimeDigestSummaryLengthRule(maxLength: 16),
            ]
        )
    }
}
