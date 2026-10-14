import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional care gap bundle must pass. Check returns its problems, or none.
    protocol RegionalCareGapBundleRule {
        func check(_ item: RegionalCareGapBundle) -> [String]
    }

    final class RegionalCareGapBundleRequiredSourceRule: RegionalCareGapBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareGapBundle) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareGapBundleNameLengthRule: RegionalCareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareGapBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareGapBundleCodePrefixRule: RegionalCareGapBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalCareGapBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalCareGapBundleExternalRefLengthRule: RegionalCareGapBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareGapBundle) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional care gap bundle.
    final class RegionalCareGapBundleValidator {
        var rules: [any RegionalCareGapBundleRule]

        init(rules: [any RegionalCareGapBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareGapBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCareGapBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareGapBundle]) -> [String: [String]] {
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

    static func defaultRegionalCareGapBundleValidator() -> RegionalCareGapBundleValidator {
        return RegionalCareGapBundleValidator(
            rules: [
                RegionalCareGapBundleRequiredSourceRule(message: "regional care gap bundle needs this field"),
                RegionalCareGapBundleNameLengthRule(maxLength: 64),
                RegionalCareGapBundleCodePrefixRule(prefix: "ACM"),
                RegionalCareGapBundleExternalRefLengthRule(maxLength: 86400),
            ]
        )
    }
}
