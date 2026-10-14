import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered care protocol summary must pass. Check returns its problems, or none.
    protocol TieredCareProtocolSummaryRule {
        func check(_ item: TieredCareProtocolSummary) -> [String]
    }

    final class TieredCareProtocolSummaryRequiredNameRule: TieredCareProtocolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolSummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolSummaryCodeLengthRule: TieredCareProtocolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareProtocolSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareProtocolSummaryRevisionRangeRule: TieredCareProtocolSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareProtocolSummary) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredCareProtocolSummaryRequiredOwnerIDRule: TieredCareProtocolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolSummary) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care protocol summary.
    final class TieredCareProtocolSummaryValidator {
        var rules: [any TieredCareProtocolSummaryRule]

        init(rules: [any TieredCareProtocolSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareProtocolSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCareProtocolSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareProtocolSummary]) -> [String: [String]] {
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

    static func defaultTieredCareProtocolSummaryValidator() -> TieredCareProtocolSummaryValidator {
        return TieredCareProtocolSummaryValidator(
            rules: [
                TieredCareProtocolSummaryRequiredNameRule(message: "tiered care protocol summary needs a value"),
                TieredCareProtocolSummaryCodeLengthRule(maxLength: 86400),
                TieredCareProtocolSummaryRevisionRangeRule(min: 16, max: 64),
                TieredCareProtocolSummaryRequiredOwnerIDRule(message: "tiered care protocol summary needs this field"),
            ]
        )
    }
}
