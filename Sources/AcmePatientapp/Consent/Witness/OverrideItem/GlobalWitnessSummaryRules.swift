import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global witness summary must pass. Check returns its problems, or none.
    protocol GlobalWitnessSummaryRule {
        func check(_ item: GlobalWitnessSummary) -> [String]
    }

    final class GlobalWitnessSummaryAllowedTitleRule: GlobalWitnessSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalWitnessSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    final class GlobalWitnessSummaryRequiredChannelRule: GlobalWitnessSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalWitnessSummary) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalWitnessSummaryChannelLengthRule: GlobalWitnessSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalWitnessSummary) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalWitnessSummaryRequiredAllergyRule: GlobalWitnessSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalWitnessSummary) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalWitnessSummaryVisibleGuardRule: GlobalWitnessSummaryRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalWitnessSummary) -> [String] {
            if item.visible && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class GlobalWitnessSummaryRequiredTitleRule: GlobalWitnessSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalWitnessSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global witness summary.
    final class GlobalWitnessSummaryValidator {
        var rules: [any GlobalWitnessSummaryRule]

        init(rules: [any GlobalWitnessSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalWitnessSummary) -> [String] {
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

        func requireValid(_ item: GlobalWitnessSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalWitnessSummary]) -> [String: [String]] {
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

    static func defaultGlobalWitnessSummaryValidator() -> GlobalWitnessSummaryValidator {
        return GlobalWitnessSummaryValidator(
            rules: [
                GlobalWitnessSummaryAllowedTitleRule(allowed: ["seasonal", "lenient", "adaptive"]),
                GlobalWitnessSummaryRequiredChannelRule(message: "global witness summary needs this field"),
                GlobalWitnessSummaryChannelLengthRule(maxLength: 3600),
                GlobalWitnessSummaryRequiredAllergyRule(message: "global witness summary needs a value"),
                GlobalWitnessSummaryVisibleGuardRule(limit: 0.1),
                GlobalWitnessSummaryRequiredTitleRule(message: "global witness summary needs a value"),
            ]
        )
    }
}
