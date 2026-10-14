import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional claim record must pass. Check returns its problems, or none.
    protocol RegionalClaimRecordRule {
        func check(_ item: RegionalClaimRecord) -> [String]
    }

    final class RegionalClaimRecordCodeLengthRule: RegionalClaimRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalClaimRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalClaimRecordRequiredPhoneRule: RegionalClaimRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClaimRecord) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClaimRecordCapacityRangeRule: RegionalClaimRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalClaimRecord) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalClaimRecordPhoneLengthRule: RegionalClaimRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalClaimRecord) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalClaimRecordAllowedCodeRule: RegionalClaimRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalClaimRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a regional claim record.
    final class RegionalClaimRecordValidator {
        var rules: [any RegionalClaimRecordRule]

        init(rules: [any RegionalClaimRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalClaimRecord) -> [String] {
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

        func requireValid(_ item: RegionalClaimRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalClaimRecord]) -> [String: [String]] {
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

    static func defaultRegionalClaimRecordValidator() -> RegionalClaimRecordValidator {
        return RegionalClaimRecordValidator(
            rules: [
                RegionalClaimRecordCodeLengthRule(maxLength: 1000),
                RegionalClaimRecordRequiredPhoneRule(message: "regional claim record needs this field"),
                RegionalClaimRecordCapacityRangeRule(min: 80, max: 86400),
                RegionalClaimRecordPhoneLengthRule(maxLength: 3600),
                RegionalClaimRecordAllowedCodeRule(allowed: []),
            ]
        )
    }
}
