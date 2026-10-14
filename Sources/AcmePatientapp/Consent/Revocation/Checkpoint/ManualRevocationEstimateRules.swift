import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual revocation estimate must pass. Check returns its problems, or none.
    protocol ManualRevocationEstimateRule {
        func check(_ item: ManualRevocationEstimate) -> [String]
    }

    final class ManualRevocationEstimateRegionLengthRule: ManualRevocationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRevocationEstimate) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRevocationEstimateRequiredRegionRule: ManualRevocationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRevocationEstimate) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRevocationEstimateAllowedTitleRule: ManualRevocationEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualRevocationEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class ManualRevocationEstimateRequiredCodeRule: ManualRevocationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRevocationEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual revocation estimate.
    final class ManualRevocationEstimateValidator {
        var rules: [any ManualRevocationEstimateRule]

        init(rules: [any ManualRevocationEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRevocationEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRevocationEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRevocationEstimate]) -> [String: [String]] {
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

    static func defaultManualRevocationEstimateValidator() -> ManualRevocationEstimateValidator {
        return ManualRevocationEstimateValidator(
            rules: [
                ManualRevocationEstimateRegionLengthRule(maxLength: 120),
                ManualRevocationEstimateRequiredRegionRule(message: "manual revocation estimate needs a value"),
                ManualRevocationEstimateAllowedTitleRule(allowed: ["tiered", "legacy"]),
                ManualRevocationEstimateRequiredCodeRule(message: "manual revocation estimate needs a value"),
            ]
        )
    }
}
