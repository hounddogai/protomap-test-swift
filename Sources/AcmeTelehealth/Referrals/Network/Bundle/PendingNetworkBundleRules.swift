import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending network bundle must pass. Check returns its problems, or none.
    protocol PendingNetworkBundleRule {
        func check(_ item: PendingNetworkBundle) -> [String]
    }

    final class PendingNetworkBundleWardLengthRule: PendingNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingNetworkBundle) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingNetworkBundleRequiredWardRule: PendingNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkBundle) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingNetworkBundleRetriesRangeRule: PendingNetworkBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingNetworkBundle) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingNetworkBundleUnitLengthRule: PendingNetworkBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingNetworkBundle) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingNetworkBundleRequiredCodeRule: PendingNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingNetworkBundleRequiredNameRule: PendingNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending network bundle.
    final class PendingNetworkBundleValidator {
        var rules: [any PendingNetworkBundleRule]

        init(rules: [any PendingNetworkBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingNetworkBundle) -> [String] {
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

        func requireValid(_ item: PendingNetworkBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingNetworkBundle]) -> [String: [String]] {
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

    static func defaultPendingNetworkBundleValidator() -> PendingNetworkBundleValidator {
        return PendingNetworkBundleValidator(
            rules: [
                PendingNetworkBundleWardLengthRule(maxLength: 80),
                PendingNetworkBundleRequiredWardRule(message: "pending network bundle needs an entry"),
                PendingNetworkBundleRetriesRangeRule(min: 16, max: 3600),
                PendingNetworkBundleUnitLengthRule(maxLength: 32),
                PendingNetworkBundleRequiredCodeRule(message: "pending network bundle needs an entry"),
                PendingNetworkBundleRequiredNameRule(message: "pending network bundle needs a value"),
            ]
        )
    }
}
