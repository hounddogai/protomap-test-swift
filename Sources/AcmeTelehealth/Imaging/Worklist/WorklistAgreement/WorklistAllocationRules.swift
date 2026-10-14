import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist allocation must pass. Check returns its problems, or none.
    protocol WorklistAllocationRule {
        func check(_ item: WorklistAllocation) -> [String]
    }

    final class WorklistAllocationRequiredCodeRule: WorklistAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistAllocationCodePrefixRule: WorklistAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistAllocationRequiredRegionRule: WorklistAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistAllocation) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistAllocationRegionLengthRule: WorklistAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistAllocation) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist allocation.
    final class WorklistAllocationValidator {
        var rules: [any WorklistAllocationRule]

        init(rules: [any WorklistAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistAllocation]) -> [String: [String]] {
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

    static func defaultWorklistAllocationValidator() -> WorklistAllocationValidator {
        return WorklistAllocationValidator(
            rules: [
                WorklistAllocationRequiredCodeRule(message: "worklist allocation needs an entry"),
                WorklistAllocationCodePrefixRule(prefix: "ACM"),
                WorklistAllocationRequiredRegionRule(message: "worklist allocation needs an entry"),
                WorklistAllocationRegionLengthRule(maxLength: 86400),
            ]
        )
    }
}
