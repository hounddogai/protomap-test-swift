import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default read allocation must pass. Check returns its problems, or none.
    protocol DefaultReadAllocationRule {
        func check(_ item: DefaultReadAllocation) -> [String]
    }

    final class DefaultReadAllocationRequiredCodeRule: DefaultReadAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReadAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReadAllocationCodePrefixRule: DefaultReadAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultReadAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultReadAllocationVersionRangeRule: DefaultReadAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReadAllocation) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultReadAllocationPhoneLengthRule: DefaultReadAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReadAllocation) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReadAllocationExternalRefLengthRule: DefaultReadAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReadAllocation) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReadAllocationRequiredExternalRefRule: DefaultReadAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReadAllocation) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default read allocation.
    final class DefaultReadAllocationValidator {
        var rules: [any DefaultReadAllocationRule]

        init(rules: [any DefaultReadAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultReadAllocation) -> [String] {
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

        func requireValid(_ item: DefaultReadAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultReadAllocation]) -> [String: [String]] {
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

    static func defaultDefaultReadAllocationValidator() -> DefaultReadAllocationValidator {
        return DefaultReadAllocationValidator(
            rules: [
                DefaultReadAllocationRequiredCodeRule(message: "default read allocation needs a value"),
                DefaultReadAllocationCodePrefixRule(prefix: "REF"),
                DefaultReadAllocationVersionRangeRule(min: 64, max: 255),
                DefaultReadAllocationPhoneLengthRule(maxLength: 64),
                DefaultReadAllocationExternalRefLengthRule(maxLength: 64),
                DefaultReadAllocationRequiredExternalRefRule(message: "default read allocation needs an entry"),
            ]
        )
    }
}
