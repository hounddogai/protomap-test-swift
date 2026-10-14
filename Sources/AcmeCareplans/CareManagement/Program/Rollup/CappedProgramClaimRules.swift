import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped program claim must pass. Check returns its problems, or none.
    protocol CappedProgramClaimRule {
        func check(_ item: CappedProgramClaim) -> [String]
    }

    final class CappedProgramClaimWindowDaysRangeRule: CappedProgramClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedProgramClaim) -> [String] {
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

    final class CappedProgramClaimQuantityRangeRule: CappedProgramClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedProgramClaim) -> [String] {
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

    final class CappedProgramClaimRequiredTitleRule: CappedProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedProgramClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedProgramClaimRequiredRegionRule: CappedProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedProgramClaim) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedProgramClaimCodePrefixRule: CappedProgramClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedProgramClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedProgramClaimCodeLengthRule: CappedProgramClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedProgramClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped program claim.
    final class CappedProgramClaimValidator {
        var rules: [any CappedProgramClaimRule]

        init(rules: [any CappedProgramClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedProgramClaim) -> [String] {
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

        func requireValid(_ item: CappedProgramClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedProgramClaim]) -> [String: [String]] {
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

    static func defaultCappedProgramClaimValidator() -> CappedProgramClaimValidator {
        return CappedProgramClaimValidator(
            rules: [
                CappedProgramClaimWindowDaysRangeRule(min: 32, max: 86400),
                CappedProgramClaimQuantityRangeRule(min: 64, max: 80),
                CappedProgramClaimRequiredTitleRule(message: "capped program claim needs an entry"),
                CappedProgramClaimRequiredRegionRule(message: "capped program claim needs a value"),
                CappedProgramClaimCodePrefixRule(prefix: "X"),
                CappedProgramClaimCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
