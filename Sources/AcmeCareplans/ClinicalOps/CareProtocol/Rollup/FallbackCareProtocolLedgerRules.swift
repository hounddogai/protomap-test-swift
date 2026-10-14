import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback care protocol ledger must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolLedgerRule {
        func check(_ item: FallbackCareProtocolLedger) -> [String]
    }

    final class FallbackCareProtocolLedgerCodePrefixRule: FallbackCareProtocolLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCareProtocolLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolLedgerNameLengthRule: FallbackCareProtocolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolLedgerWindowDaysRangeRule: FallbackCareProtocolLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolLedger) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol ledger.
    final class FallbackCareProtocolLedgerValidator {
        var rules: [any FallbackCareProtocolLedgerRule]

        init(rules: [any FallbackCareProtocolLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCareProtocolLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolLedger]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolLedgerValidator() -> FallbackCareProtocolLedgerValidator {
        return FallbackCareProtocolLedgerValidator(
            rules: [
                FallbackCareProtocolLedgerCodePrefixRule(prefix: "OPS"),
                FallbackCareProtocolLedgerNameLengthRule(maxLength: 86400),
                FallbackCareProtocolLedgerWindowDaysRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
