import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary order set cycle must pass. Check returns its problems, or none.
    protocol PrimaryOrderSetCycleRule {
        func check(_ item: PrimaryOrderSetCycle) -> [String]
    }

    final class PrimaryOrderSetCycleOwnerIDLengthRule: PrimaryOrderSetCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOrderSetCycle) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetCycleQuantityRangeRule: PrimaryOrderSetCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOrderSetCycle) -> [String] {
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

    final class PrimaryOrderSetCycleLabelLengthRule: PrimaryOrderSetCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOrderSetCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetCycleAllowedCodeRule: PrimaryOrderSetCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryOrderSetCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a primary order set cycle.
    final class PrimaryOrderSetCycleValidator {
        var rules: [any PrimaryOrderSetCycleRule]

        init(rules: [any PrimaryOrderSetCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOrderSetCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryOrderSetCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOrderSetCycle]) -> [String: [String]] {
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

    static func defaultPrimaryOrderSetCycleValidator() -> PrimaryOrderSetCycleValidator {
        return PrimaryOrderSetCycleValidator(
            rules: [
                PrimaryOrderSetCycleOwnerIDLengthRule(maxLength: 16),
                PrimaryOrderSetCycleQuantityRangeRule(min: 64, max: 255),
                PrimaryOrderSetCycleLabelLengthRule(maxLength: 32),
                PrimaryOrderSetCycleAllowedCodeRule(allowed: []),
            ]
        )
    }
}
