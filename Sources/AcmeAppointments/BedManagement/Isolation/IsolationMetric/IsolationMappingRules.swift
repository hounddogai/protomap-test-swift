import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation mapping must pass. Check returns its problems, or none.
    protocol IsolationMappingRule {
        func check(_ item: IsolationMapping) -> [String]
    }

    final class IsolationMappingCodePrefixRule: IsolationMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class IsolationMappingCodeLengthRule: IsolationMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationMappingPinnedGuardRule: IsolationMappingRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: IsolationMapping) -> [String] {
            if item.pinned && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class IsolationMappingCopayRangeRule: IsolationMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationMapping) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationMappingRequiredCodeRule: IsolationMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationMappingAllowedCodeRule: IsolationMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation mapping.
    final class IsolationMappingValidator {
        var rules: [any IsolationMappingRule]

        init(rules: [any IsolationMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationMapping) -> [String] {
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

        func requireValid(_ item: IsolationMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationMapping]) -> [String: [String]] {
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

    static func defaultIsolationMappingValidator() -> IsolationMappingValidator {
        return IsolationMappingValidator(
            rules: [
                IsolationMappingCodePrefixRule(prefix: "OPS"),
                IsolationMappingCodeLengthRule(maxLength: 64),
                IsolationMappingPinnedGuardRule(limit: 8.4),
                IsolationMappingCopayRangeRule(min: 7.5, max: 324.0),
                IsolationMappingRequiredCodeRule(message: "isolation mapping needs a value"),
                IsolationMappingAllowedCodeRule(allowed: []),
            ]
        )
    }
}
