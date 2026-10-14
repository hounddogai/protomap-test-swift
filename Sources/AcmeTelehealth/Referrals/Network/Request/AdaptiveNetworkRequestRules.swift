import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive network request must pass. Check returns its problems, or none.
    protocol AdaptiveNetworkRequestRule {
        func check(_ item: AdaptiveNetworkRequest) -> [String]
    }

    final class AdaptiveNetworkRequestRequiredFacilityRule: AdaptiveNetworkRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveNetworkRequest) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveNetworkRequestContactEmailLengthRule: AdaptiveNetworkRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveNetworkRequest) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveNetworkRequestAllowedContactEmailRule: AdaptiveNetworkRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveNetworkRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive network request.
    final class AdaptiveNetworkRequestValidator {
        var rules: [any AdaptiveNetworkRequestRule]

        init(rules: [any AdaptiveNetworkRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveNetworkRequest) -> [String] {
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

        func requireValid(_ item: AdaptiveNetworkRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveNetworkRequest]) -> [String: [String]] {
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

    static func defaultAdaptiveNetworkRequestValidator() -> AdaptiveNetworkRequestValidator {
        return AdaptiveNetworkRequestValidator(
            rules: [
                AdaptiveNetworkRequestRequiredFacilityRule(message: "adaptive network request needs a value"),
                AdaptiveNetworkRequestContactEmailLengthRule(maxLength: 80),
                AdaptiveNetworkRequestAllowedContactEmailRule(allowed: ["tiered", "regional", "tiered"]),
            ]
        )
    }
}
