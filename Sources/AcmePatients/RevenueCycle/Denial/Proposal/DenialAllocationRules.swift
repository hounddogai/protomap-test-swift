import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial allocation must pass. Check returns its problems, or none.
    protocol DenialAllocationRule {
        func check(_ item: DenialAllocation) -> [String]
    }

    final class DenialAllocationCodeLengthRule: DenialAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialAllocationTitleLengthRule: DenialAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialAllocationCodePrefixRule: DenialAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial allocation.
    final class DenialAllocationValidator {
        var rules: [any DenialAllocationRule]

        init(rules: [any DenialAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialAllocation]) -> [String: [String]] {
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

    static func defaultDenialAllocationValidator() -> DenialAllocationValidator {
        return DenialAllocationValidator(
            rules: [
                DenialAllocationCodeLengthRule(maxLength: 1000),
                DenialAllocationTitleLengthRule(maxLength: 120),
                DenialAllocationCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
