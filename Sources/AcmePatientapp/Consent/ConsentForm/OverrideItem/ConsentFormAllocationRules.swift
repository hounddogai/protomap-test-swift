import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form allocation must pass. Check returns its problems, or none.
    protocol ConsentFormAllocationRule {
        func check(_ item: ConsentFormAllocation) -> [String]
    }

    final class ConsentFormAllocationLocaleLengthRule: ConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormAllocation) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormAllocationCodePrefixRule: ConsentFormAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormAllocationAllowedFacilityRule: ConsentFormAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form allocation.
    final class ConsentFormAllocationValidator {
        var rules: [any ConsentFormAllocationRule]

        init(rules: [any ConsentFormAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormAllocation) -> [String] {
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

        func requireValid(_ item: ConsentFormAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormAllocation]) -> [String: [String]] {
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

    static func defaultConsentFormAllocationValidator() -> ConsentFormAllocationValidator {
        return ConsentFormAllocationValidator(
            rules: [
                ConsentFormAllocationLocaleLengthRule(maxLength: 120),
                ConsentFormAllocationCodePrefixRule(prefix: "X"),
                ConsentFormAllocationAllowedFacilityRule(allowed: ["global", "pending"]),
            ]
        )
    }
}
