import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol bundle must pass. Check returns its problems, or none.
    protocol CareProtocolBundleRule {
        func check(_ item: CareProtocolBundle) -> [String]
    }

    final class CareProtocolBundleAllowedBedRule: CareProtocolBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is duplicated"]
            }
            return []
        }
    }

    final class CareProtocolBundleRequiredCodeRule: CareProtocolBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolBundleCodeLengthRule: CareProtocolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolBundleUpdatedAtRangeRule: CareProtocolBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolBundle) -> [String] {
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

    final class CareProtocolBundleScoreRangeRule: CareProtocolBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolBundle) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol bundle.
    final class CareProtocolBundleValidator {
        var rules: [any CareProtocolBundleRule]

        init(rules: [any CareProtocolBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolBundle]) -> [String: [String]] {
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

    static func defaultCareProtocolBundleValidator() -> CareProtocolBundleValidator {
        return CareProtocolBundleValidator(
            rules: [
                CareProtocolBundleAllowedBedRule(allowed: ["pending", "adaptive"]),
                CareProtocolBundleRequiredCodeRule(message: "care protocol bundle needs this field"),
                CareProtocolBundleCodeLengthRule(maxLength: 3600),
                CareProtocolBundleUpdatedAtRangeRule(min: 32, max: 3600),
                CareProtocolBundleScoreRangeRule(min: 9.5, max: 1758.2),
            ]
        )
    }
}
