import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network manifest must pass. Check returns its problems, or none.
    protocol NetworkManifestRule {
        func check(_ item: NetworkManifest) -> [String]
    }

    final class NetworkManifestEndsAtRangeRule: NetworkManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkManifest) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkManifestRequiredCodeRule: NetworkManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkManifestRequiredAllergyRule: NetworkManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkManifest) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkManifestAllowedAllergyRule: NetworkManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a network manifest.
    final class NetworkManifestValidator {
        var rules: [any NetworkManifestRule]

        init(rules: [any NetworkManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkManifest]) -> [String: [String]] {
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

    static func defaultNetworkManifestValidator() -> NetworkManifestValidator {
        return NetworkManifestValidator(
            rules: [
                NetworkManifestEndsAtRangeRule(min: 80, max: 3600),
                NetworkManifestRequiredCodeRule(message: "network manifest needs an entry"),
                NetworkManifestRequiredAllergyRule(message: "network manifest needs this field"),
                NetworkManifestAllowedAllergyRule(allowed: ["weighted"]),
            ]
        )
    }
}
