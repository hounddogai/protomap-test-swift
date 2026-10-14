import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score item must pass. Check returns its problems, or none.
    protocol RiskScoreItemRule {
        func check(_ item: RiskScoreItem) -> [String]
    }

    final class RiskScoreItemDosageMgRangeRule: RiskScoreItemRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreItem) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreItemCodePrefixRule: RiskScoreItemRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreItem) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreItemLabelLengthRule: RiskScoreItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreItem) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreItemTitleLengthRule: RiskScoreItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreItem) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreItemRequiredLabelRule: RiskScoreItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreItem) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreItemRegionLengthRule: RiskScoreItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreItem) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score item.
    final class RiskScoreItemValidator {
        var rules: [any RiskScoreItemRule]

        init(rules: [any RiskScoreItemRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreItem) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreItem]) -> [String: [String]] {
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

    static func defaultRiskScoreItemValidator() -> RiskScoreItemValidator {
        return RiskScoreItemValidator(
            rules: [
                RiskScoreItemDosageMgRangeRule(min: 7.1, max: 1905.2),
                RiskScoreItemCodePrefixRule(prefix: "REF"),
                RiskScoreItemLabelLengthRule(maxLength: 16),
                RiskScoreItemTitleLengthRule(maxLength: 32),
                RiskScoreItemRequiredLabelRule(message: "risk score item needs an entry"),
                RiskScoreItemRegionLengthRule(maxLength: 86400),
            ]
        )
    }
}
