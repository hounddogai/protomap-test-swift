import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge record must pass. Check returns its problems, or none.
    protocol ChargeRecordRule {
        func check(_ item: ChargeRecord) -> [String]
    }

    final class ChargeRecordRetriesRangeRule: ChargeRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeRecord) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeRecordAllowedLabelRule: ChargeRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class ChargeRecordRequiredCodeRule: ChargeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge record.
    final class ChargeRecordValidator {
        var rules: [any ChargeRecordRule]

        init(rules: [any ChargeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeRecord]) -> [String: [String]] {
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

    static func defaultChargeRecordValidator() -> ChargeRecordValidator {
        return ChargeRecordValidator(
            rules: [
                ChargeRecordRetriesRangeRule(min: 64, max: 255),
                ChargeRecordAllowedLabelRule(allowed: ["legacy"]),
                ChargeRecordRequiredCodeRule(message: "charge record needs an entry"),
            ]
        )
    }
}
