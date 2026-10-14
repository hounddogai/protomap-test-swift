import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary consent form entry must pass. Check returns its problems, or none.
    protocol PrimaryConsentFormEntryRule {
        func check(_ item: PrimaryConsentFormEntry) -> [String]
    }

    final class PrimaryConsentFormEntryNameLengthRule: PrimaryConsentFormEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryConsentFormEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryConsentFormEntryCodeLengthRule: PrimaryConsentFormEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryConsentFormEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryConsentFormEntryLimitRangeRule: PrimaryConsentFormEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryConsentFormEntry) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary consent form entry.
    final class PrimaryConsentFormEntryValidator {
        var rules: [any PrimaryConsentFormEntryRule]

        init(rules: [any PrimaryConsentFormEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryConsentFormEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryConsentFormEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryConsentFormEntry]) -> [String: [String]] {
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

    static func defaultPrimaryConsentFormEntryValidator() -> PrimaryConsentFormEntryValidator {
        return PrimaryConsentFormEntryValidator(
            rules: [
                PrimaryConsentFormEntryNameLengthRule(maxLength: 16),
                PrimaryConsentFormEntryCodeLengthRule(maxLength: 86400),
                PrimaryConsentFormEntryLimitRangeRule(min: 255, max: 255),
            ]
        )
    }
}
