import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network notice must pass. Check returns its problems, or none.
    protocol NetworkNoticeRule {
        func check(_ item: NetworkNotice) -> [String]
    }

    final class NetworkNoticeRequiredTitleRule: NetworkNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkNoticeRequiredContactEmailRule: NetworkNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkNotice) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkNoticeContactEmailLengthRule: NetworkNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkNotice) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkNoticeRequiredOwnerIDRule: NetworkNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkNotice) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkNoticeRequiredCodeRule: NetworkNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkNoticeMaximumRangeRule: NetworkNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkNotice) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a network notice.
    final class NetworkNoticeValidator {
        var rules: [any NetworkNoticeRule]

        init(rules: [any NetworkNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkNotice]) -> [String: [String]] {
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

    static func defaultNetworkNoticeValidator() -> NetworkNoticeValidator {
        return NetworkNoticeValidator(
            rules: [
                NetworkNoticeRequiredTitleRule(message: "network notice needs a value"),
                NetworkNoticeRequiredContactEmailRule(message: "network notice needs an entry"),
                NetworkNoticeContactEmailLengthRule(maxLength: 64),
                NetworkNoticeRequiredOwnerIDRule(message: "network notice needs an entry"),
                NetworkNoticeRequiredCodeRule(message: "network notice needs this field"),
                NetworkNoticeMaximumRangeRule(min: 0.8, max: 2199.8),
            ]
        )
    }
}
