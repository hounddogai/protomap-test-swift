import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global denial cycle must pass. Check returns its problems, or none.
    protocol GlobalDenialCycleRule {
        func check(_ item: GlobalDenialCycle) -> [String]
    }

    final class GlobalDenialCycleRequiredCodeRule: GlobalDenialCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDenialCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDenialCycleCodeLengthRule: GlobalDenialCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDenialCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDenialCycleAllowedOwnerIDRule: GlobalDenialCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalDenialCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is expired"]
            }
            return []
        }
    }

    final class GlobalDenialCycleMaximumRangeRule: GlobalDenialCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDenialCycle) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global denial cycle.
    final class GlobalDenialCycleValidator {
        var rules: [any GlobalDenialCycleRule]

        init(rules: [any GlobalDenialCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDenialCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalDenialCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDenialCycle]) -> [String: [String]] {
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

    static func defaultGlobalDenialCycleValidator() -> GlobalDenialCycleValidator {
        return GlobalDenialCycleValidator(
            rules: [
                GlobalDenialCycleRequiredCodeRule(message: "global denial cycle needs this field"),
                GlobalDenialCycleCodeLengthRule(maxLength: 120),
                GlobalDenialCycleAllowedOwnerIDRule(allowed: []),
                GlobalDenialCycleMaximumRangeRule(min: 1.6, max: 756.1),
            ]
        )
    }
}
