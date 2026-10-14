import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive network snapshot must pass. Check returns its problems, or none.
    protocol AdaptiveNetworkSnapshotRule {
        func check(_ item: AdaptiveNetworkSnapshot) -> [String]
    }

    final class AdaptiveNetworkSnapshotRequiredPatientRefRule: AdaptiveNetworkSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveNetworkSnapshot) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveNetworkSnapshotCodePrefixRule: AdaptiveNetworkSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveNetworkSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveNetworkSnapshotEndsAtRangeRule: AdaptiveNetworkSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveNetworkSnapshot) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveNetworkSnapshotCodeLengthRule: AdaptiveNetworkSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveNetworkSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive network snapshot.
    final class AdaptiveNetworkSnapshotValidator {
        var rules: [any AdaptiveNetworkSnapshotRule]

        init(rules: [any AdaptiveNetworkSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveNetworkSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveNetworkSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveNetworkSnapshot]) -> [String: [String]] {
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

    static func defaultAdaptiveNetworkSnapshotValidator() -> AdaptiveNetworkSnapshotValidator {
        return AdaptiveNetworkSnapshotValidator(
            rules: [
                AdaptiveNetworkSnapshotRequiredPatientRefRule(message: "adaptive network snapshot needs an entry"),
                AdaptiveNetworkSnapshotCodePrefixRule(prefix: "ACM"),
                AdaptiveNetworkSnapshotEndsAtRangeRule(min: 3600, max: 86400),
                AdaptiveNetworkSnapshotCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
