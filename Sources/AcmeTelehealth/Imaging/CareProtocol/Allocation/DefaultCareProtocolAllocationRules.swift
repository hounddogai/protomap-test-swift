import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default care protocol allocation must pass. Check returns its problems, or none.
    protocol DefaultCareProtocolAllocationRule {
        func check(_ item: DefaultCareProtocolAllocation) -> [String]
    }

    final class DefaultCareProtocolAllocationRequiredTitleRule: DefaultCareProtocolAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCareProtocolAllocationRefillsRangeRule: DefaultCareProtocolAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCareProtocolAllocation) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolAllocationCodeLengthRule: DefaultCareProtocolAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolAllocationRequiredCodeRule: DefaultCareProtocolAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCareProtocolAllocationDiagnosisCodeLengthRule: DefaultCareProtocolAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolAllocation) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolAllocationAllowedCodeRule: DefaultCareProtocolAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCareProtocolAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a default care protocol allocation.
    final class DefaultCareProtocolAllocationValidator {
        var rules: [any DefaultCareProtocolAllocationRule]

        init(rules: [any DefaultCareProtocolAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareProtocolAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCareProtocolAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareProtocolAllocation]) -> [String: [String]] {
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

    static func defaultDefaultCareProtocolAllocationValidator() -> DefaultCareProtocolAllocationValidator {
        return DefaultCareProtocolAllocationValidator(
            rules: [
                DefaultCareProtocolAllocationRequiredTitleRule(
                    message: "default care protocol allocation needs an entry"
                ),
                DefaultCareProtocolAllocationRefillsRangeRule(min: 120, max: 3600),
                DefaultCareProtocolAllocationCodeLengthRule(maxLength: 86400),
                DefaultCareProtocolAllocationRequiredCodeRule(
                    message: "default care protocol allocation needs this field"
                ),
                DefaultCareProtocolAllocationDiagnosisCodeLengthRule(maxLength: 86400),
                DefaultCareProtocolAllocationAllowedCodeRule(allowed: ["manual", "capped"]),
            ]
        )
    }
}
