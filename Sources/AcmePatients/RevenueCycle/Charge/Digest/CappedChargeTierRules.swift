import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped charge tier must pass. Check returns its problems, or none.
    protocol CappedChargeTierRule {
        func check(_ item: CappedChargeTier) -> [String]
    }

    final class CappedChargeTierRequiredNameRule: CappedChargeTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedChargeTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedChargeTierGraceDaysRangeRule: CappedChargeTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedChargeTier) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedChargeTierDiagnosisCodeLengthRule: CappedChargeTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedChargeTier) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedChargeTierApprovedGuardRule: CappedChargeTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedChargeTier) -> [String] {
            if item.approved && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class CappedChargeTierNameLengthRule: CappedChargeTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedChargeTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedChargeTierEndsAtRangeRule: CappedChargeTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedChargeTier) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped charge tier.
    final class CappedChargeTierValidator {
        var rules: [any CappedChargeTierRule]

        init(rules: [any CappedChargeTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedChargeTier) -> [String] {
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

        func requireValid(_ item: CappedChargeTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedChargeTier]) -> [String: [String]] {
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

    static func defaultCappedChargeTierValidator() -> CappedChargeTierValidator {
        return CappedChargeTierValidator(
            rules: [
                CappedChargeTierRequiredNameRule(message: "capped charge tier needs this field"),
                CappedChargeTierGraceDaysRangeRule(min: 16, max: 80),
                CappedChargeTierDiagnosisCodeLengthRule(maxLength: 255),
                CappedChargeTierApprovedGuardRule(limit: 80),
                CappedChargeTierNameLengthRule(maxLength: 16),
                CappedChargeTierEndsAtRangeRule(min: 80, max: 255),
            ]
        )
    }
}
