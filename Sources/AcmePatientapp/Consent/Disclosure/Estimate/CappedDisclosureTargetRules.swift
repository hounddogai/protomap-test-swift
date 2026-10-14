import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped disclosure target must pass. Check returns its problems, or none.
    protocol CappedDisclosureTargetRule {
        func check(_ item: CappedDisclosureTarget) -> [String]
    }

    final class CappedDisclosureTargetVersionRangeRule: CappedDisclosureTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDisclosureTarget) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedDisclosureTargetWardLengthRule: CappedDisclosureTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDisclosureTarget) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedDisclosureTargetCodeLengthRule: CappedDisclosureTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDisclosureTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedDisclosureTargetCodePrefixRule: CappedDisclosureTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDisclosureTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedDisclosureTargetRequiredEncounterIDRule: CappedDisclosureTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDisclosureTarget) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped disclosure target.
    final class CappedDisclosureTargetValidator {
        var rules: [any CappedDisclosureTargetRule]

        init(rules: [any CappedDisclosureTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDisclosureTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedDisclosureTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDisclosureTarget]) -> [String: [String]] {
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

    static func defaultCappedDisclosureTargetValidator() -> CappedDisclosureTargetValidator {
        return CappedDisclosureTargetValidator(
            rules: [
                CappedDisclosureTargetVersionRangeRule(min: 16, max: 80),
                CappedDisclosureTargetWardLengthRule(maxLength: 86400),
                CappedDisclosureTargetCodeLengthRule(maxLength: 80),
                CappedDisclosureTargetCodePrefixRule(prefix: "ACM"),
                CappedDisclosureTargetRequiredEncounterIDRule(message: "capped disclosure target needs an entry"),
            ]
        )
    }
}
