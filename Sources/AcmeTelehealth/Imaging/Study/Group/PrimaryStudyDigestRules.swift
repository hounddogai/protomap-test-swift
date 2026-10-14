import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary study digest must pass. Check returns its problems, or none.
    protocol PrimaryStudyDigestRule {
        func check(_ item: PrimaryStudyDigest) -> [String]
    }

    final class PrimaryStudyDigestWardLengthRule: PrimaryStudyDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryStudyDigest) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryStudyDigestAllowedWardRule: PrimaryStudyDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryStudyDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is duplicated"]
            }
            return []
        }
    }

    final class PrimaryStudyDigestEndsAtRangeRule: PrimaryStudyDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryStudyDigest) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryStudyDigestCodePrefixRule: PrimaryStudyDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryStudyDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryStudyDigestBudgetRangeRule: PrimaryStudyDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryStudyDigest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryStudyDigestRequiredNameRule: PrimaryStudyDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStudyDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary study digest.
    final class PrimaryStudyDigestValidator {
        var rules: [any PrimaryStudyDigestRule]

        init(rules: [any PrimaryStudyDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryStudyDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryStudyDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryStudyDigest]) -> [String: [String]] {
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

    static func defaultPrimaryStudyDigestValidator() -> PrimaryStudyDigestValidator {
        return PrimaryStudyDigestValidator(
            rules: [
                PrimaryStudyDigestWardLengthRule(maxLength: 1000),
                PrimaryStudyDigestAllowedWardRule(allowed: []),
                PrimaryStudyDigestEndsAtRangeRule(min: 32, max: 32),
                PrimaryStudyDigestCodePrefixRule(prefix: "Q"),
                PrimaryStudyDigestBudgetRangeRule(min: 2.3, max: 178.8),
                PrimaryStudyDigestRequiredNameRule(message: "primary study digest needs a value"),
            ]
        )
    }
}
