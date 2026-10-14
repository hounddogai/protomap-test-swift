import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network cycle must pass. Check returns its problems, or none.
    protocol ManualNetworkCycleRule {
        func check(_ item: ManualNetworkCycle) -> [String]
    }

    final class ManualNetworkCycleCodeLengthRule: ManualNetworkCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkCycleRequiredCodeRule: ManualNetworkCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualNetworkCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualNetworkCycleSummaryLengthRule: ManualNetworkCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkCycle) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual network cycle.
    final class ManualNetworkCycleValidator {
        var rules: [any ManualNetworkCycleRule]

        init(rules: [any ManualNetworkCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualNetworkCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkCycle]) -> [String: [String]] {
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

    static func defaultManualNetworkCycleValidator() -> ManualNetworkCycleValidator {
        return ManualNetworkCycleValidator(
            rules: [
                ManualNetworkCycleCodeLengthRule(maxLength: 255),
                ManualNetworkCycleRequiredCodeRule(message: "manual network cycle needs this field"),
                ManualNetworkCycleSummaryLengthRule(maxLength: 80),
            ]
        )
    }
}
