import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score manifest must pass. Check returns its problems, or none.
    protocol RiskScoreManifestRule {
        func check(_ item: RiskScoreManifest) -> [String]
    }

    final class RiskScoreManifestRevisionRangeRule: RiskScoreManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreManifest) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreManifestStartsAtRangeRule: RiskScoreManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreManifest) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreManifestRequiredChannelRule: RiskScoreManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreManifest) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreManifestGraceDaysRangeRule: RiskScoreManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreManifest) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a risk score manifest.
    final class RiskScoreManifestValidator {
        var rules: [any RiskScoreManifestRule]

        init(rules: [any RiskScoreManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreManifest]) -> [String: [String]] {
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

    static func defaultRiskScoreManifestValidator() -> RiskScoreManifestValidator {
        return RiskScoreManifestValidator(
            rules: [
                RiskScoreManifestRevisionRangeRule(min: 3600, max: 86400),
                RiskScoreManifestStartsAtRangeRule(min: 64, max: 120),
                RiskScoreManifestRequiredChannelRule(message: "risk score manifest needs this field"),
                RiskScoreManifestGraceDaysRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
