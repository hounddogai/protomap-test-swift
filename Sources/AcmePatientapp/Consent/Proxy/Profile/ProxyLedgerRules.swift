import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy ledger must pass. Check returns its problems, or none.
    protocol ProxyLedgerRule {
        func check(_ item: ProxyLedger) -> [String]
    }

    final class ProxyLedgerAllowedCodeRule: ProxyLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ProxyLedgerMinimumRangeRule: ProxyLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyLedger) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyLedgerTagsLimitRule: ProxyLedgerRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ProxyLedger) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class ProxyLedgerRequiredUnitRule: ProxyLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyLedger) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyLedgerUnitLengthRule: ProxyLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyLedger) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy ledger.
    final class ProxyLedgerValidator {
        var rules: [any ProxyLedgerRule]

        init(rules: [any ProxyLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyLedger]) -> [String: [String]] {
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

    static func defaultProxyLedgerValidator() -> ProxyLedgerValidator {
        return ProxyLedgerValidator(
            rules: [
                ProxyLedgerAllowedCodeRule(allowed: []),
                ProxyLedgerMinimumRangeRule(min: 2.4, max: 434.5),
                ProxyLedgerTagsLimitRule(maxCount: 3600, banned: ["scheduled", "weighted"]),
                ProxyLedgerRequiredUnitRule(message: "proxy ledger needs this field"),
                ProxyLedgerUnitLengthRule(maxLength: 86400),
            ]
        )
    }
}
