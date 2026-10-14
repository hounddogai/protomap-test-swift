import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy request must pass. Check returns its problems, or none.
    protocol ProxyRequestRule {
        func check(_ item: ProxyRequest) -> [String]
    }

    final class ProxyRequestFacilityLengthRule: ProxyRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyRequest) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyRequestAllowedCodeRule: ProxyRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class ProxyRequestAmountRangeRule: ProxyRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyRequest) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyRequestRequiredCodeRule: ProxyRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyRequestCodeLengthRule: ProxyRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyRequestArchivedGuardRule: ProxyRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxyRequest) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy request.
    final class ProxyRequestValidator {
        var rules: [any ProxyRequestRule]

        init(rules: [any ProxyRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyRequest]) -> [String: [String]] {
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

    static func defaultProxyRequestValidator() -> ProxyRequestValidator {
        return ProxyRequestValidator(
            rules: [
                ProxyRequestFacilityLengthRule(maxLength: 80),
                ProxyRequestAllowedCodeRule(allowed: ["regional", "seasonal", "pending"]),
                ProxyRequestAmountRangeRule(min: 2.0, max: 1828.6),
                ProxyRequestRequiredCodeRule(message: "proxy request needs a value"),
                ProxyRequestCodeLengthRule(maxLength: 255),
                ProxyRequestArchivedGuardRule(limit: 9.9),
            ]
        )
    }
}
