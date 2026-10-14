import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient read mapping must pass. Check returns its problems, or none.
    protocol LenientReadMappingRule {
        func check(_ item: LenientReadMapping) -> [String]
    }

    final class LenientReadMappingRequiredOwnerIDRule: LenientReadMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReadMapping) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReadMappingCodePrefixRule: LenientReadMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientReadMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientReadMappingAllowedOwnerIDRule: LenientReadMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientReadMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is expired"]
            }
            return []
        }
    }

    final class LenientReadMappingNameLengthRule: LenientReadMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReadMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientReadMappingLimitRangeRule: LenientReadMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReadMapping) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient read mapping.
    final class LenientReadMappingValidator {
        var rules: [any LenientReadMappingRule]

        init(rules: [any LenientReadMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReadMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientReadMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReadMapping]) -> [String: [String]] {
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

    static func defaultLenientReadMappingValidator() -> LenientReadMappingValidator {
        return LenientReadMappingValidator(
            rules: [
                LenientReadMappingRequiredOwnerIDRule(message: "lenient read mapping needs this field"),
                LenientReadMappingCodePrefixRule(prefix: "REF"),
                LenientReadMappingAllowedOwnerIDRule(allowed: ["tiered"]),
                LenientReadMappingNameLengthRule(maxLength: 16),
                LenientReadMappingLimitRangeRule(min: 16, max: 120),
            ]
        )
    }
}
