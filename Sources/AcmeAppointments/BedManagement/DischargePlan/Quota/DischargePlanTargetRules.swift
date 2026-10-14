import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan target must pass. Check returns its problems, or none.
    protocol DischargePlanTargetRule {
        func check(_ item: DischargePlanTarget) -> [String]
    }

    final class DischargePlanTargetAllowedRegionRule: DischargePlanTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is stale"]
            }
            return []
        }
    }

    final class DischargePlanTargetRequiredNameRule: DischargePlanTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanTargetCodePrefixRule: DischargePlanTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanTargetNameLengthRule: DischargePlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanTargetRegionLengthRule: DischargePlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanTarget) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanTargetCodeLengthRule: DischargePlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan target.
    final class DischargePlanTargetValidator {
        var rules: [any DischargePlanTargetRule]

        init(rules: [any DischargePlanTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanTarget) -> [String] {
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

        func requireValid(_ item: DischargePlanTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanTarget]) -> [String: [String]] {
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

    static func defaultDischargePlanTargetValidator() -> DischargePlanTargetValidator {
        return DischargePlanTargetValidator(
            rules: [
                DischargePlanTargetAllowedRegionRule(allowed: ["batched", "scheduled"]),
                DischargePlanTargetRequiredNameRule(message: "discharge plan target needs this field"),
                DischargePlanTargetCodePrefixRule(prefix: "REF"),
                DischargePlanTargetNameLengthRule(maxLength: 64),
                DischargePlanTargetRegionLengthRule(maxLength: 1000),
                DischargePlanTargetCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
