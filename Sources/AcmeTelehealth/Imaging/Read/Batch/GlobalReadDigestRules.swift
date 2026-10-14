import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global read digest must pass. Check returns its problems, or none.
    protocol GlobalReadDigestRule {
        func check(_ item: GlobalReadDigest) -> [String]
    }

    final class GlobalReadDigestExternalRefLengthRule: GlobalReadDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReadDigest) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReadDigestRequiredCodeRule: GlobalReadDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReadDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReadDigestCeilingRangeRule: GlobalReadDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReadDigest) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalReadDigestRequiredExternalRefRule: GlobalReadDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReadDigest) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReadDigestCodePrefixRule: GlobalReadDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalReadDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalReadDigestMinimumRangeRule: GlobalReadDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReadDigest) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global read digest.
    final class GlobalReadDigestValidator {
        var rules: [any GlobalReadDigestRule]

        init(rules: [any GlobalReadDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReadDigest) -> [String] {
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

        func requireValid(_ item: GlobalReadDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReadDigest]) -> [String: [String]] {
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

    static func defaultGlobalReadDigestValidator() -> GlobalReadDigestValidator {
        return GlobalReadDigestValidator(
            rules: [
                GlobalReadDigestExternalRefLengthRule(maxLength: 80),
                GlobalReadDigestRequiredCodeRule(message: "global read digest needs an entry"),
                GlobalReadDigestCeilingRangeRule(min: 7.1, max: 907.5),
                GlobalReadDigestRequiredExternalRefRule(message: "global read digest needs a value"),
                GlobalReadDigestCodePrefixRule(prefix: "REF"),
                GlobalReadDigestMinimumRangeRule(min: 2.8, max: 3642.7),
            ]
        )
    }
}
