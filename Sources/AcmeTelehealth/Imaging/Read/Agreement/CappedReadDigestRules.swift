import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped read digest must pass. Check returns its problems, or none.
    protocol CappedReadDigestRule {
        func check(_ item: CappedReadDigest) -> [String]
    }

    final class CappedReadDigestRequiredBedRule: CappedReadDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReadDigest) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReadDigestRateRangeRule: CappedReadDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReadDigest) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedReadDigestRequiredNameRule: CappedReadDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReadDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReadDigestRequiredCodeRule: CappedReadDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReadDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReadDigestCodePrefixRule: CappedReadDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedReadDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedReadDigestBedLengthRule: CappedReadDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReadDigest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped read digest.
    final class CappedReadDigestValidator {
        var rules: [any CappedReadDigestRule]

        init(rules: [any CappedReadDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReadDigest) -> [String] {
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

        func requireValid(_ item: CappedReadDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReadDigest]) -> [String: [String]] {
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

    static func defaultCappedReadDigestValidator() -> CappedReadDigestValidator {
        return CappedReadDigestValidator(
            rules: [
                CappedReadDigestRequiredBedRule(message: "capped read digest needs this field"),
                CappedReadDigestRateRangeRule(min: 5.6, max: 843.3),
                CappedReadDigestRequiredNameRule(message: "capped read digest needs an entry"),
                CappedReadDigestRequiredCodeRule(message: "capped read digest needs this field"),
                CappedReadDigestCodePrefixRule(prefix: "REF"),
                CappedReadDigestBedLengthRule(maxLength: 120),
            ]
        )
    }
}
