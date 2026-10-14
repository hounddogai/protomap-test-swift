import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy cycle must pass. Check returns its problems, or none.
    protocol ProxyCycleRule {
        func check(_ item: ProxyCycle) -> [String]
    }

    final class ProxyCycleApprovedGuardRule: ProxyCycleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxyCycle) -> [String] {
            if item.approved && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ProxyCycleRequiredChannelRule: ProxyCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyCycle) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyCycleRequiredNameRule: ProxyCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyCycleCodePrefixRule: ProxyCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyCycleChannelLengthRule: ProxyCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyCycle) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy cycle.
    final class ProxyCycleValidator {
        var rules: [any ProxyCycleRule]

        init(rules: [any ProxyCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyCycle]) -> [String: [String]] {
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

    static func defaultProxyCycleValidator() -> ProxyCycleValidator {
        return ProxyCycleValidator(
            rules: [
                ProxyCycleApprovedGuardRule(limit: 8.6),
                ProxyCycleRequiredChannelRule(message: "proxy cycle needs a value"),
                ProxyCycleRequiredNameRule(message: "proxy cycle needs an entry"),
                ProxyCycleCodePrefixRule(prefix: "OPS"),
                ProxyCycleChannelLengthRule(maxLength: 32),
            ]
        )
    }
}
