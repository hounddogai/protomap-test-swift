import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback transfer request must pass. Check returns its problems, or none.
    protocol FallbackTransferRequestRule {
        func check(_ item: FallbackTransferRequest) -> [String]
    }

    final class FallbackTransferRequestTitleLengthRule: FallbackTransferRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackTransferRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackTransferRequestEndsAtRangeRule: FallbackTransferRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackTransferRequest) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackTransferRequestCodePrefixRule: FallbackTransferRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackTransferRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackTransferRequestDiscountRangeRule: FallbackTransferRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackTransferRequest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackTransferRequestRequiredCodeRule: FallbackTransferRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackTransferRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackTransferRequestAllowedTitleRule: FallbackTransferRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackTransferRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback transfer request.
    final class FallbackTransferRequestValidator {
        var rules: [any FallbackTransferRequestRule]

        init(rules: [any FallbackTransferRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackTransferRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackTransferRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackTransferRequest]) -> [String: [String]] {
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

    static func defaultFallbackTransferRequestValidator() -> FallbackTransferRequestValidator {
        return FallbackTransferRequestValidator(
            rules: [
                FallbackTransferRequestTitleLengthRule(maxLength: 120),
                FallbackTransferRequestEndsAtRangeRule(min: 64, max: 120),
                FallbackTransferRequestCodePrefixRule(prefix: "OPS"),
                FallbackTransferRequestDiscountRangeRule(min: 1.6, max: 2188.8),
                FallbackTransferRequestRequiredCodeRule(message: "fallback transfer request needs this field"),
                FallbackTransferRequestAllowedTitleRule(allowed: []),
            ]
        )
    }
}
