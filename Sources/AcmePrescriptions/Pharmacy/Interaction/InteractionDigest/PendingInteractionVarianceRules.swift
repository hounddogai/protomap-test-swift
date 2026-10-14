import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending interaction variance must pass. Check returns its problems, or none.
    protocol PendingInteractionVarianceRule {
        func check(_ item: PendingInteractionVariance) -> [String]
    }

    final class PendingInteractionVarianceRequiredCodeRule: PendingInteractionVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingInteractionVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingInteractionVarianceExpiresAtRangeRule: PendingInteractionVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingInteractionVariance) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingInteractionVarianceCodePrefixRule: PendingInteractionVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingInteractionVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingInteractionVarianceRequiredChecksumRule: PendingInteractionVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingInteractionVariance) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingInteractionVarianceTitleLengthRule: PendingInteractionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingInteractionVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending interaction variance.
    final class PendingInteractionVarianceValidator {
        var rules: [any PendingInteractionVarianceRule]

        init(rules: [any PendingInteractionVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingInteractionVariance) -> [String] {
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

        func requireValid(_ item: PendingInteractionVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingInteractionVariance]) -> [String: [String]] {
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

    static func defaultPendingInteractionVarianceValidator() -> PendingInteractionVarianceValidator {
        return PendingInteractionVarianceValidator(
            rules: [
                PendingInteractionVarianceRequiredCodeRule(message: "pending interaction variance needs this field"),
                PendingInteractionVarianceExpiresAtRangeRule(min: 255, max: 1000),
                PendingInteractionVarianceCodePrefixRule(prefix: "X"),
                PendingInteractionVarianceRequiredChecksumRule(message: "pending interaction variance needs a value"),
                PendingInteractionVarianceTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
