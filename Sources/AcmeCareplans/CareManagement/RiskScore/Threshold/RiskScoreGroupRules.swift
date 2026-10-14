import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score group must pass. Check returns its problems, or none.
    protocol RiskScoreGroupRule {
        func check(_ item: RiskScoreGroup) -> [String]
    }

    final class RiskScoreGroupQuantityRangeRule: RiskScoreGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreGroup) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreGroupFloorValueRangeRule: RiskScoreGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreGroup) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreGroupApprovedGuardRule: RiskScoreGroupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RiskScoreGroup) -> [String] {
            if item.approved && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RiskScoreGroupVisitMinutesRangeRule: RiskScoreGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreGroup) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreGroupCodePrefixRule: RiskScoreGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreGroupCodeLengthRule: RiskScoreGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score group.
    final class RiskScoreGroupValidator {
        var rules: [any RiskScoreGroupRule]

        init(rules: [any RiskScoreGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreGroup]) -> [String: [String]] {
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

    static func defaultRiskScoreGroupValidator() -> RiskScoreGroupValidator {
        return RiskScoreGroupValidator(
            rules: [
                RiskScoreGroupQuantityRangeRule(min: 64, max: 64),
                RiskScoreGroupFloorValueRangeRule(min: 5.9, max: 4862.6),
                RiskScoreGroupApprovedGuardRule(limit: 1.4),
                RiskScoreGroupVisitMinutesRangeRule(min: 16, max: 64),
                RiskScoreGroupCodePrefixRule(prefix: "OPS"),
                RiskScoreGroupCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
