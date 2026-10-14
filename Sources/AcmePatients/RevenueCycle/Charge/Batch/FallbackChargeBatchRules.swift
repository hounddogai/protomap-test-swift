import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback charge batch must pass. Check returns its problems, or none.
    protocol FallbackChargeBatchRule {
        func check(_ item: FallbackChargeBatch) -> [String]
    }

    final class FallbackChargeBatchRequiredCodeRule: FallbackChargeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackChargeBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackChargeBatchAllowedFacilityRule: FallbackChargeBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackChargeBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is unknown"]
            }
            return []
        }
    }

    final class FallbackChargeBatchRequiredTitleRule: FallbackChargeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackChargeBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackChargeBatchTitleLengthRule: FallbackChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackChargeBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackChargeBatchFacilityLengthRule: FallbackChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackChargeBatch) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback charge batch.
    final class FallbackChargeBatchValidator {
        var rules: [any FallbackChargeBatchRule]

        init(rules: [any FallbackChargeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackChargeBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackChargeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackChargeBatch]) -> [String: [String]] {
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

    static func defaultFallbackChargeBatchValidator() -> FallbackChargeBatchValidator {
        return FallbackChargeBatchValidator(
            rules: [
                FallbackChargeBatchRequiredCodeRule(message: "fallback charge batch needs an entry"),
                FallbackChargeBatchAllowedFacilityRule(allowed: []),
                FallbackChargeBatchRequiredTitleRule(message: "fallback charge batch needs an entry"),
                FallbackChargeBatchTitleLengthRule(maxLength: 64),
                FallbackChargeBatchFacilityLengthRule(maxLength: 1000),
            ]
        )
    }
}
