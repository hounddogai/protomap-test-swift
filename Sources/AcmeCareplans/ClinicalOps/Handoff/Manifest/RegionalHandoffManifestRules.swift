import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional handoff manifest must pass. Check returns its problems, or none.
    protocol RegionalHandoffManifestRule {
        func check(_ item: RegionalHandoffManifest) -> [String]
    }

    final class RegionalHandoffManifestRequiredLabelRule: RegionalHandoffManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalHandoffManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalHandoffManifestFacilityLengthRule: RegionalHandoffManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalHandoffManifest) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalHandoffManifestGraceDaysRangeRule: RegionalHandoffManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalHandoffManifest) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalHandoffManifestCodeLengthRule: RegionalHandoffManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalHandoffManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional handoff manifest.
    final class RegionalHandoffManifestValidator {
        var rules: [any RegionalHandoffManifestRule]

        init(rules: [any RegionalHandoffManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalHandoffManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalHandoffManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalHandoffManifest]) -> [String: [String]] {
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

    static func defaultRegionalHandoffManifestValidator() -> RegionalHandoffManifestValidator {
        return RegionalHandoffManifestValidator(
            rules: [
                RegionalHandoffManifestRequiredLabelRule(message: "regional handoff manifest needs this field"),
                RegionalHandoffManifestFacilityLengthRule(maxLength: 3600),
                RegionalHandoffManifestGraceDaysRangeRule(min: 32, max: 64),
                RegionalHandoffManifestCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
