import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient transfer allocation must pass. Check returns its problems, or none.
    protocol LenientTransferAllocationRule {
        func check(_ item: LenientTransferAllocation) -> [String]
    }

    final class LenientTransferAllocationCreatedAtRangeRule: LenientTransferAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientTransferAllocation) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientTransferAllocationScoreRangeRule: LenientTransferAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientTransferAllocation) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientTransferAllocationRequiredCodeRule: LenientTransferAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTransferAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientTransferAllocationAllowedCodeRule: LenientTransferAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientTransferAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient transfer allocation.
    final class LenientTransferAllocationValidator {
        var rules: [any LenientTransferAllocationRule]

        init(rules: [any LenientTransferAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientTransferAllocation) -> [String] {
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

        func requireValid(_ item: LenientTransferAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientTransferAllocation]) -> [String: [String]] {
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

    static func defaultLenientTransferAllocationValidator() -> LenientTransferAllocationValidator {
        return LenientTransferAllocationValidator(
            rules: [
                LenientTransferAllocationCreatedAtRangeRule(min: 120, max: 255),
                LenientTransferAllocationScoreRangeRule(min: 6.8, max: 4510.9),
                LenientTransferAllocationRequiredCodeRule(message: "lenient transfer allocation needs a value"),
                LenientTransferAllocationAllowedCodeRule(allowed: []),
            ]
        )
    }
}
