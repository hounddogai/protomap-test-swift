import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default overtime digest must pass. Check returns its problems, or none.
    protocol DefaultOvertimeDigestRule {
        func check(_ item: DefaultOvertimeDigest) -> [String]
    }

    final class DefaultOvertimeDigestEndsAtRangeRule: DefaultOvertimeDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultOvertimeDigest) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultOvertimeDigestRequiredCodeRule: DefaultOvertimeDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOvertimeDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultOvertimeDigestChecksumLengthRule: DefaultOvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultOvertimeDigest) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultOvertimeDigestNameLengthRule: DefaultOvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultOvertimeDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultOvertimeDigestDosageMgRangeRule: DefaultOvertimeDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultOvertimeDigest) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultOvertimeDigestCodePrefixRule: DefaultOvertimeDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultOvertimeDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default overtime digest.
    final class DefaultOvertimeDigestValidator {
        var rules: [any DefaultOvertimeDigestRule]

        init(rules: [any DefaultOvertimeDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultOvertimeDigest) -> [String] {
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

        func requireValid(_ item: DefaultOvertimeDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultOvertimeDigest]) -> [String: [String]] {
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

    static func defaultDefaultOvertimeDigestValidator() -> DefaultOvertimeDigestValidator {
        return DefaultOvertimeDigestValidator(
            rules: [
                DefaultOvertimeDigestEndsAtRangeRule(min: 16, max: 80),
                DefaultOvertimeDigestRequiredCodeRule(message: "default overtime digest needs an entry"),
                DefaultOvertimeDigestChecksumLengthRule(maxLength: 1000),
                DefaultOvertimeDigestNameLengthRule(maxLength: 3600),
                DefaultOvertimeDigestDosageMgRangeRule(min: 8.8, max: 3479.5),
                DefaultOvertimeDigestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
