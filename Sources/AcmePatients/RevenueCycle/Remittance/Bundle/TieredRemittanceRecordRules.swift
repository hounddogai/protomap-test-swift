import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered remittance record must pass. Check returns its problems, or none.
    protocol TieredRemittanceRecordRule {
        func check(_ item: TieredRemittanceRecord) -> [String]
    }

    final class TieredRemittanceRecordUpdatedAtRangeRule: TieredRemittanceRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRemittanceRecord) -> [String] {
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

    final class TieredRemittanceRecordAllowedNameRule: TieredRemittanceRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredRemittanceRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class TieredRemittanceRecordRequiredCodeRule: TieredRemittanceRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRemittanceRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered remittance record.
    final class TieredRemittanceRecordValidator {
        var rules: [any TieredRemittanceRecordRule]

        init(rules: [any TieredRemittanceRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRemittanceRecord) -> [String] {
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

        func requireValid(_ item: TieredRemittanceRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRemittanceRecord]) -> [String: [String]] {
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

    static func defaultTieredRemittanceRecordValidator() -> TieredRemittanceRecordValidator {
        return TieredRemittanceRecordValidator(
            rules: [
                TieredRemittanceRecordUpdatedAtRangeRule(min: 16, max: 64),
                TieredRemittanceRecordAllowedNameRule(allowed: []),
                TieredRemittanceRecordRequiredCodeRule(message: "tiered remittance record needs an entry"),
            ]
        )
    }
}
