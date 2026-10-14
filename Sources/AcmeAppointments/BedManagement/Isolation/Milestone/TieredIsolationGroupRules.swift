import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered isolation group must pass. Check returns its problems, or none.
    protocol TieredIsolationGroupRule {
        func check(_ item: TieredIsolationGroup) -> [String]
    }

    final class TieredIsolationGroupNameLengthRule: TieredIsolationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredIsolationGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredIsolationGroupAllowedContactEmailRule: TieredIsolationGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredIsolationGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is blocked"]
            }
            return []
        }
    }

    final class TieredIsolationGroupCodePrefixRule: TieredIsolationGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredIsolationGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered isolation group.
    final class TieredIsolationGroupValidator {
        var rules: [any TieredIsolationGroupRule]

        init(rules: [any TieredIsolationGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredIsolationGroup) -> [String] {
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

        func requireValid(_ item: TieredIsolationGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredIsolationGroup]) -> [String: [String]] {
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

    static func defaultTieredIsolationGroupValidator() -> TieredIsolationGroupValidator {
        return TieredIsolationGroupValidator(
            rules: [
                TieredIsolationGroupNameLengthRule(maxLength: 32),
                TieredIsolationGroupAllowedContactEmailRule(allowed: ["strict"]),
                TieredIsolationGroupCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
