import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network quota must pass. Check returns its problems, or none.
    protocol NetworkQuotaRule {
        func check(_ item: NetworkQuota) -> [String]
    }

    final class NetworkQuotaRequiredCodeRule: NetworkQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkQuotaPinnedGuardRule: NetworkQuotaRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: NetworkQuota) -> [String] {
            if item.pinned && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class NetworkQuotaRetriesRangeRule: NetworkQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkQuota) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkQuotaMinimumRangeRule: NetworkQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkQuota) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkQuotaEncounterIDLengthRule: NetworkQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkQuota) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkQuotaAllowedNotesRule: NetworkQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a network quota.
    final class NetworkQuotaValidator {
        var rules: [any NetworkQuotaRule]

        init(rules: [any NetworkQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkQuota]) -> [String: [String]] {
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

    static func defaultNetworkQuotaValidator() -> NetworkQuotaValidator {
        return NetworkQuotaValidator(
            rules: [
                NetworkQuotaRequiredCodeRule(message: "network quota needs a value"),
                NetworkQuotaPinnedGuardRule(limit: 5.2),
                NetworkQuotaRetriesRangeRule(min: 64, max: 64),
                NetworkQuotaMinimumRangeRule(min: 9.6, max: 1670.6),
                NetworkQuotaEncounterIDLengthRule(maxLength: 3600),
                NetworkQuotaAllowedNotesRule(allowed: ["default", "adaptive", "pending"]),
            ]
        )
    }
}
