import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global program claim must pass. Check returns its problems, or none.
    protocol GlobalProgramClaimRule {
        func check(_ item: GlobalProgramClaim) -> [String]
    }

    final class GlobalProgramClaimApprovedGuardRule: GlobalProgramClaimRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalProgramClaim) -> [String] {
            if item.approved && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class GlobalProgramClaimDosageMgRangeRule: GlobalProgramClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalProgramClaim) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalProgramClaimCodePrefixRule: GlobalProgramClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalProgramClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalProgramClaimWindowDaysRangeRule: GlobalProgramClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalProgramClaim) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalProgramClaimStartsAtRangeRule: GlobalProgramClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalProgramClaim) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalProgramClaimRequiredLocaleRule: GlobalProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalProgramClaim) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global program claim.
    final class GlobalProgramClaimValidator {
        var rules: [any GlobalProgramClaimRule]

        init(rules: [any GlobalProgramClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalProgramClaim) -> [String] {
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

        func requireValid(_ item: GlobalProgramClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalProgramClaim]) -> [String: [String]] {
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

    static func defaultGlobalProgramClaimValidator() -> GlobalProgramClaimValidator {
        return GlobalProgramClaimValidator(
            rules: [
                GlobalProgramClaimApprovedGuardRule(limit: 80),
                GlobalProgramClaimDosageMgRangeRule(min: 2.6, max: 2186.0),
                GlobalProgramClaimCodePrefixRule(prefix: "X"),
                GlobalProgramClaimWindowDaysRangeRule(min: 16, max: 3600),
                GlobalProgramClaimStartsAtRangeRule(min: 16, max: 120),
                GlobalProgramClaimRequiredLocaleRule(message: "global program claim needs a value"),
            ]
        )
    }
}
