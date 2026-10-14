import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional network score must pass. Check returns its problems, or none.
    protocol RegionalNetworkScoreRule {
        func check(_ item: RegionalNetworkScore) -> [String]
    }

    final class RegionalNetworkScoreRequiredNameRule: RegionalNetworkScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalNetworkScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalNetworkScoreNameLengthRule: RegionalNetworkScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalNetworkScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalNetworkScoreCodePrefixRule: RegionalNetworkScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalNetworkScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalNetworkScoreRequiredClinicianIDRule: RegionalNetworkScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalNetworkScore) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalNetworkScoreRequiredCodeRule: RegionalNetworkScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalNetworkScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalNetworkScoreUnitLengthRule: RegionalNetworkScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalNetworkScore) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional network score.
    final class RegionalNetworkScoreValidator {
        var rules: [any RegionalNetworkScoreRule]

        init(rules: [any RegionalNetworkScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalNetworkScore) -> [String] {
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

        func requireValid(_ item: RegionalNetworkScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalNetworkScore]) -> [String: [String]] {
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

    static func defaultRegionalNetworkScoreValidator() -> RegionalNetworkScoreValidator {
        return RegionalNetworkScoreValidator(
            rules: [
                RegionalNetworkScoreRequiredNameRule(message: "regional network score needs a value"),
                RegionalNetworkScoreNameLengthRule(maxLength: 1000),
                RegionalNetworkScoreCodePrefixRule(prefix: "ACM"),
                RegionalNetworkScoreRequiredClinicianIDRule(message: "regional network score needs this field"),
                RegionalNetworkScoreRequiredCodeRule(message: "regional network score needs a value"),
                RegionalNetworkScoreUnitLengthRule(maxLength: 3600),
            ]
        )
    }
}
