import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure bundle must pass. Check returns its problems, or none.
    protocol DisclosureBundleRule {
        func check(_ item: DisclosureBundle) -> [String]
    }

    final class DisclosureBundleUpdatedAtRangeRule: DisclosureBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureBundle) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureBundleTitleLengthRule: DisclosureBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureBundleAllowedDescriptionRule: DisclosureBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is stale"]
            }
            return []
        }
    }

    final class DisclosureBundleRequiredCodeRule: DisclosureBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureBundleRequiredEncounterIDRule: DisclosureBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureBundle) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure bundle.
    final class DisclosureBundleValidator {
        var rules: [any DisclosureBundleRule]

        init(rules: [any DisclosureBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureBundle) -> [String] {
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

        func requireValid(_ item: DisclosureBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureBundle]) -> [String: [String]] {
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

    static func defaultDisclosureBundleValidator() -> DisclosureBundleValidator {
        return DisclosureBundleValidator(
            rules: [
                DisclosureBundleUpdatedAtRangeRule(min: 64, max: 3600),
                DisclosureBundleTitleLengthRule(maxLength: 86400),
                DisclosureBundleAllowedDescriptionRule(allowed: []),
                DisclosureBundleRequiredCodeRule(message: "disclosure bundle needs this field"),
                DisclosureBundleRequiredEncounterIDRule(message: "disclosure bundle needs this field"),
            ]
        )
    }
}
