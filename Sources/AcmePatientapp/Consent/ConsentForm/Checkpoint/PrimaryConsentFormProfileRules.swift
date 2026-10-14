import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary consent form profile must pass. Check returns its problems, or none.
    protocol PrimaryConsentFormProfileRule {
        func check(_ item: PrimaryConsentFormProfile) -> [String]
    }

    final class PrimaryConsentFormProfileRequiredSpecialtyRule: PrimaryConsentFormProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryConsentFormProfile) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryConsentFormProfileCodePrefixRule: PrimaryConsentFormProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryConsentFormProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryConsentFormProfileRequiredSegmentRule: PrimaryConsentFormProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryConsentFormProfile) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryConsentFormProfileRetriesRangeRule: PrimaryConsentFormProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryConsentFormProfile) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary consent form profile.
    final class PrimaryConsentFormProfileValidator {
        var rules: [any PrimaryConsentFormProfileRule]

        init(rules: [any PrimaryConsentFormProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryConsentFormProfile) -> [String] {
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

        func requireValid(_ item: PrimaryConsentFormProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryConsentFormProfile]) -> [String: [String]] {
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

    static func defaultPrimaryConsentFormProfileValidator() -> PrimaryConsentFormProfileValidator {
        return PrimaryConsentFormProfileValidator(
            rules: [
                PrimaryConsentFormProfileRequiredSpecialtyRule(message: "primary consent form profile needs an entry"),
                PrimaryConsentFormProfileCodePrefixRule(prefix: "REF"),
                PrimaryConsentFormProfileRequiredSegmentRule(message: "primary consent form profile needs this field"),
                PrimaryConsentFormProfileRetriesRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
