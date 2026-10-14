import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback network entry must pass. Check returns its problems, or none.
    protocol FallbackNetworkEntryRule {
        func check(_ item: FallbackNetworkEntry) -> [String]
    }

    final class FallbackNetworkEntryCodePrefixRule: FallbackNetworkEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackNetworkEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackNetworkEntryOwnerIDLengthRule: FallbackNetworkEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackNetworkEntry) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackNetworkEntryCapacityRangeRule: FallbackNetworkEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackNetworkEntry) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackNetworkEntryRequiredCodeRule: FallbackNetworkEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackNetworkEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackNetworkEntryRequiredOwnerIDRule: FallbackNetworkEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackNetworkEntry) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackNetworkEntryCodeLengthRule: FallbackNetworkEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackNetworkEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback network entry.
    final class FallbackNetworkEntryValidator {
        var rules: [any FallbackNetworkEntryRule]

        init(rules: [any FallbackNetworkEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackNetworkEntry) -> [String] {
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

        func requireValid(_ item: FallbackNetworkEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackNetworkEntry]) -> [String: [String]] {
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

    static func defaultFallbackNetworkEntryValidator() -> FallbackNetworkEntryValidator {
        return FallbackNetworkEntryValidator(
            rules: [
                FallbackNetworkEntryCodePrefixRule(prefix: "OPS"),
                FallbackNetworkEntryOwnerIDLengthRule(maxLength: 3600),
                FallbackNetworkEntryCapacityRangeRule(min: 80, max: 3600),
                FallbackNetworkEntryRequiredCodeRule(message: "fallback network entry needs an entry"),
                FallbackNetworkEntryRequiredOwnerIDRule(message: "fallback network entry needs an entry"),
                FallbackNetworkEntryCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
