import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict witness quota must pass. Check returns its problems, or none.
    protocol StrictWitnessQuotaRule {
        func check(_ item: StrictWitnessQuota) -> [String]
    }

    final class StrictWitnessQuotaRequiredTitleRule: StrictWitnessQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWitnessQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWitnessQuotaCodePrefixRule: StrictWitnessQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictWitnessQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictWitnessQuotaCapacityRangeRule: StrictWitnessQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictWitnessQuota) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictWitnessQuotaCodeLengthRule: StrictWitnessQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWitnessQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictWitnessQuotaTitleLengthRule: StrictWitnessQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWitnessQuota) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict witness quota.
    final class StrictWitnessQuotaValidator {
        var rules: [any StrictWitnessQuotaRule]

        init(rules: [any StrictWitnessQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWitnessQuota) -> [String] {
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

        func requireValid(_ item: StrictWitnessQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWitnessQuota]) -> [String: [String]] {
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

    static func defaultStrictWitnessQuotaValidator() -> StrictWitnessQuotaValidator {
        return StrictWitnessQuotaValidator(
            rules: [
                StrictWitnessQuotaRequiredTitleRule(message: "strict witness quota needs this field"),
                StrictWitnessQuotaCodePrefixRule(prefix: "REF"),
                StrictWitnessQuotaCapacityRangeRule(min: 120, max: 255),
                StrictWitnessQuotaCodeLengthRule(maxLength: 255),
                StrictWitnessQuotaTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
