import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling transfer segment must pass. Check returns its problems, or none.
    protocol RollingTransferSegmentRule {
        func check(_ item: RollingTransferSegment) -> [String]
    }

    final class RollingTransferSegmentAllowedNameRule: RollingTransferSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingTransferSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class RollingTransferSegmentFloorValueRangeRule: RollingTransferSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingTransferSegment) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingTransferSegmentCeilingRangeRule: RollingTransferSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingTransferSegment) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingTransferSegmentRequiredPayerRule: RollingTransferSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTransferSegment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling transfer segment.
    final class RollingTransferSegmentValidator {
        var rules: [any RollingTransferSegmentRule]

        init(rules: [any RollingTransferSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingTransferSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingTransferSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingTransferSegment]) -> [String: [String]] {
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

    static func defaultRollingTransferSegmentValidator() -> RollingTransferSegmentValidator {
        return RollingTransferSegmentValidator(
            rules: [
                RollingTransferSegmentAllowedNameRule(allowed: []),
                RollingTransferSegmentFloorValueRangeRule(min: 5.2, max: 1714.2),
                RollingTransferSegmentCeilingRangeRule(min: 7.8, max: 4520.5),
                RollingTransferSegmentRequiredPayerRule(message: "rolling transfer segment needs a value"),
            ]
        )
    }
}
