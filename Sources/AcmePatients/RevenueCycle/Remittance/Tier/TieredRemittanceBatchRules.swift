import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered remittance batch must pass. Check returns its problems, or none.
    protocol TieredRemittanceBatchRule {
        func check(_ item: TieredRemittanceBatch) -> [String]
    }

    final class TieredRemittanceBatchBedLengthRule: TieredRemittanceBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceBatch) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRemittanceBatchRequiredCodeRule: TieredRemittanceBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRemittanceBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRemittanceBatchExpiresAtRangeRule: TieredRemittanceBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRemittanceBatch) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRemittanceBatchSpecialtyLengthRule: TieredRemittanceBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceBatch) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRemittanceBatchAllowedSpecialtyRule: TieredRemittanceBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredRemittanceBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered remittance batch.
    final class TieredRemittanceBatchValidator {
        var rules: [any TieredRemittanceBatchRule]

        init(rules: [any TieredRemittanceBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRemittanceBatch) -> [String] {
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

        func requireValid(_ item: TieredRemittanceBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRemittanceBatch]) -> [String: [String]] {
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

    static func defaultTieredRemittanceBatchValidator() -> TieredRemittanceBatchValidator {
        return TieredRemittanceBatchValidator(
            rules: [
                TieredRemittanceBatchBedLengthRule(maxLength: 120),
                TieredRemittanceBatchRequiredCodeRule(message: "tiered remittance batch needs an entry"),
                TieredRemittanceBatchExpiresAtRangeRule(min: 80, max: 86400),
                TieredRemittanceBatchSpecialtyLengthRule(maxLength: 1000),
                TieredRemittanceBatchAllowedSpecialtyRule(allowed: []),
            ]
        )
    }
}
