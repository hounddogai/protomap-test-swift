import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending consent form allocation must pass. Check returns its problems, or none.
    protocol PendingConsentFormAllocationRule {
        func check(_ item: PendingConsentFormAllocation) -> [String]
    }

    final class PendingConsentFormAllocationMarginRangeRule: PendingConsentFormAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingConsentFormAllocation) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingConsentFormAllocationCodePrefixRule: PendingConsentFormAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingConsentFormAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingConsentFormAllocationNameLengthRule: PendingConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingConsentFormAllocation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingConsentFormAllocationCodeLengthRule: PendingConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingConsentFormAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending consent form allocation.
    final class PendingConsentFormAllocationValidator {
        var rules: [any PendingConsentFormAllocationRule]

        init(rules: [any PendingConsentFormAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingConsentFormAllocation) -> [String] {
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

        func requireValid(_ item: PendingConsentFormAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingConsentFormAllocation]) -> [String: [String]] {
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

    static func defaultPendingConsentFormAllocationValidator() -> PendingConsentFormAllocationValidator {
        return PendingConsentFormAllocationValidator(
            rules: [
                PendingConsentFormAllocationMarginRangeRule(min: 5.7, max: 2470.2),
                PendingConsentFormAllocationCodePrefixRule(prefix: "REF"),
                PendingConsentFormAllocationNameLengthRule(maxLength: 32),
                PendingConsentFormAllocationCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
