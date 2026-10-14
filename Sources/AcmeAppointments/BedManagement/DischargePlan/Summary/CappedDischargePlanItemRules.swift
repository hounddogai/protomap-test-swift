import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped discharge plan item must pass. Check returns its problems, or none.
    protocol CappedDischargePlanItemRule {
        func check(_ item: CappedDischargePlanItem) -> [String]
    }

    final class CappedDischargePlanItemRequiredCodeRule: CappedDischargePlanItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDischargePlanItem) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDischargePlanItemCodePrefixRule: CappedDischargePlanItemRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDischargePlanItem) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedDischargePlanItemRegionLengthRule: CappedDischargePlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDischargePlanItem) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedDischargePlanItemNameLengthRule: CappedDischargePlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDischargePlanItem) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped discharge plan item.
    final class CappedDischargePlanItemValidator {
        var rules: [any CappedDischargePlanItemRule]

        init(rules: [any CappedDischargePlanItemRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDischargePlanItem) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedDischargePlanItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDischargePlanItem]) -> [String: [String]] {
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

    static func defaultCappedDischargePlanItemValidator() -> CappedDischargePlanItemValidator {
        return CappedDischargePlanItemValidator(
            rules: [
                CappedDischargePlanItemRequiredCodeRule(message: "capped discharge plan item needs an entry"),
                CappedDischargePlanItemCodePrefixRule(prefix: "Q"),
                CappedDischargePlanItemRegionLengthRule(maxLength: 64),
                CappedDischargePlanItemNameLengthRule(maxLength: 16),
            ]
        )
    }
}
