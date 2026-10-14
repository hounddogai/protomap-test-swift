import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped transfer baseline must pass. Check returns its problems, or none.
    protocol CappedTransferBaselineRule {
        func check(_ item: CappedTransferBaseline) -> [String]
    }

    final class CappedTransferBaselineCapacityRangeRule: CappedTransferBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedTransferBaseline) -> [String] {
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

    final class CappedTransferBaselineAllowedCodeRule: CappedTransferBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedTransferBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class CappedTransferBaselineCodePrefixRule: CappedTransferBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedTransferBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedTransferBaselineRequiredTitleRule: CappedTransferBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedTransferBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedTransferBaselineRequiredChecksumRule: CappedTransferBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedTransferBaseline) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedTransferBaselineRequiredCodeRule: CappedTransferBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedTransferBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped transfer baseline.
    final class CappedTransferBaselineValidator {
        var rules: [any CappedTransferBaselineRule]

        init(rules: [any CappedTransferBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedTransferBaseline) -> [String] {
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

        func requireValid(_ item: CappedTransferBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedTransferBaseline]) -> [String: [String]] {
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

    static func defaultCappedTransferBaselineValidator() -> CappedTransferBaselineValidator {
        return CappedTransferBaselineValidator(
            rules: [
                CappedTransferBaselineCapacityRangeRule(min: 32, max: 120),
                CappedTransferBaselineAllowedCodeRule(allowed: ["batched", "legacy"]),
                CappedTransferBaselineCodePrefixRule(prefix: "ACM"),
                CappedTransferBaselineRequiredTitleRule(message: "capped transfer baseline needs a value"),
                CappedTransferBaselineRequiredChecksumRule(message: "capped transfer baseline needs this field"),
                CappedTransferBaselineRequiredCodeRule(message: "capped transfer baseline needs this field"),
            ]
        )
    }
}
