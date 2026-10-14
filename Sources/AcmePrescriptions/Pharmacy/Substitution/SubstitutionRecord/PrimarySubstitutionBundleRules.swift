import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary substitution bundle must pass. Check returns its problems, or none.
    protocol PrimarySubstitutionBundleRule {
        func check(_ item: PrimarySubstitutionBundle) -> [String]
    }

    final class PrimarySubstitutionBundleRequiredNameRule: PrimarySubstitutionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionBundleVersionRangeRule: PrimarySubstitutionBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySubstitutionBundle) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimarySubstitutionBundleRequiredCodeRule: PrimarySubstitutionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionBundleRequiredChecksumRule: PrimarySubstitutionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionBundle) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary substitution bundle.
    final class PrimarySubstitutionBundleValidator {
        var rules: [any PrimarySubstitutionBundleRule]

        init(rules: [any PrimarySubstitutionBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySubstitutionBundle) -> [String] {
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

        func requireValid(_ item: PrimarySubstitutionBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySubstitutionBundle]) -> [String: [String]] {
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

    static func defaultPrimarySubstitutionBundleValidator() -> PrimarySubstitutionBundleValidator {
        return PrimarySubstitutionBundleValidator(
            rules: [
                PrimarySubstitutionBundleRequiredNameRule(message: "primary substitution bundle needs this field"),
                PrimarySubstitutionBundleVersionRangeRule(min: 32, max: 1000),
                PrimarySubstitutionBundleRequiredCodeRule(message: "primary substitution bundle needs an entry"),
                PrimarySubstitutionBundleRequiredChecksumRule(message: "primary substitution bundle needs an entry"),
            ]
        )
    }
}
