import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered rounding request must pass. Check returns its problems, or none.
    protocol TieredRoundingRequestRule {
        func check(_ item: TieredRoundingRequest) -> [String]
    }

    final class TieredRoundingRequestTimezoneLengthRule: TieredRoundingRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRoundingRequest) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRoundingRequestApprovedGuardRule: TieredRoundingRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredRoundingRequest) -> [String] {
            if item.approved && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredRoundingRequestRequiredTimezoneRule: TieredRoundingRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRoundingRequest) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered rounding request.
    final class TieredRoundingRequestValidator {
        var rules: [any TieredRoundingRequestRule]

        init(rules: [any TieredRoundingRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRoundingRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRoundingRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRoundingRequest]) -> [String: [String]] {
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

    static func defaultTieredRoundingRequestValidator() -> TieredRoundingRequestValidator {
        return TieredRoundingRequestValidator(
            rules: [
                TieredRoundingRequestTimezoneLengthRule(maxLength: 86400),
                TieredRoundingRequestApprovedGuardRule(limit: 7.4),
                TieredRoundingRequestRequiredTimezoneRule(message: "tiered rounding request needs this field"),
            ]
        )
    }
}
