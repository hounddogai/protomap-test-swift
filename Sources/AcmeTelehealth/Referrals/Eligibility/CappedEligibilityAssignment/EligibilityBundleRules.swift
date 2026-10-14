import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility bundle must pass. Check returns its problems, or none.
    protocol EligibilityBundleRule {
        func check(_ item: EligibilityBundle) -> [String]
    }

    final class EligibilityBundleTitleLengthRule: EligibilityBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityBundleRequiredCodeRule: EligibilityBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityBundleCostRangeRule: EligibilityBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityBundle) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityBundleCodeLengthRule: EligibilityBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityBundleCodePrefixRule: EligibilityBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityBundleRequiredOwnerIDRule: EligibilityBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityBundle) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility bundle.
    final class EligibilityBundleValidator {
        var rules: [any EligibilityBundleRule]

        init(rules: [any EligibilityBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityBundle) -> [String] {
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

        func requireValid(_ item: EligibilityBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityBundle]) -> [String: [String]] {
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

    static func defaultEligibilityBundleValidator() -> EligibilityBundleValidator {
        return EligibilityBundleValidator(
            rules: [
                EligibilityBundleTitleLengthRule(maxLength: 3600),
                EligibilityBundleRequiredCodeRule(message: "eligibility bundle needs this field"),
                EligibilityBundleCostRangeRule(min: 6.2, max: 2375.7),
                EligibilityBundleCodeLengthRule(maxLength: 64),
                EligibilityBundleCodePrefixRule(prefix: "REF"),
                EligibilityBundleRequiredOwnerIDRule(message: "eligibility bundle needs this field"),
            ]
        )
    }
}
