import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional claim bundle must pass. Check returns its problems, or none.
    protocol RegionalClaimBundleRule {
        func check(_ item: RegionalClaimBundle) -> [String]
    }

    final class RegionalClaimBundleRetriesRangeRule: RegionalClaimBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalClaimBundle) -> [String] {
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

    final class RegionalClaimBundleRequiredClinicianIDRule: RegionalClaimBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClaimBundle) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClaimBundleLabelLengthRule: RegionalClaimBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalClaimBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional claim bundle.
    final class RegionalClaimBundleValidator {
        var rules: [any RegionalClaimBundleRule]

        init(rules: [any RegionalClaimBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalClaimBundle) -> [String] {
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

        func requireValid(_ item: RegionalClaimBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalClaimBundle]) -> [String: [String]] {
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

    static func defaultRegionalClaimBundleValidator() -> RegionalClaimBundleValidator {
        return RegionalClaimBundleValidator(
            rules: [
                RegionalClaimBundleRetriesRangeRule(min: 120, max: 86400),
                RegionalClaimBundleRequiredClinicianIDRule(message: "regional claim bundle needs an entry"),
                RegionalClaimBundleLabelLengthRule(maxLength: 1000),
            ]
        )
    }
}
