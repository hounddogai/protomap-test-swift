import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient care gap allocation must pass. Check returns its problems, or none.
    protocol LenientCareGapAllocationRule {
        func check(_ item: LenientCareGapAllocation) -> [String]
    }

    final class LenientCareGapAllocationActiveGuardRule: LenientCareGapAllocationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientCareGapAllocation) -> [String] {
            if item.active && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class LenientCareGapAllocationLocaleLengthRule: LenientCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareGapAllocation) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareGapAllocationAllowedTitleRule: LenientCareGapAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientCareGapAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class LenientCareGapAllocationRequiredCodeRule: LenientCareGapAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCareGapAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCareGapAllocationCodeLengthRule: LenientCareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareGapAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient care gap allocation.
    final class LenientCareGapAllocationValidator {
        var rules: [any LenientCareGapAllocationRule]

        init(rules: [any LenientCareGapAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareGapAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCareGapAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareGapAllocation]) -> [String: [String]] {
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

    static func defaultLenientCareGapAllocationValidator() -> LenientCareGapAllocationValidator {
        return LenientCareGapAllocationValidator(
            rules: [
                LenientCareGapAllocationActiveGuardRule(limit: 120),
                LenientCareGapAllocationLocaleLengthRule(maxLength: 64),
                LenientCareGapAllocationAllowedTitleRule(allowed: ["pending", "scheduled"]),
                LenientCareGapAllocationRequiredCodeRule(message: "lenient care gap allocation needs an entry"),
                LenientCareGapAllocationCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
