import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive claim snapshot must pass. Check returns its problems, or none.
    protocol AdaptiveClaimSnapshotRule {
        func check(_ item: AdaptiveClaimSnapshot) -> [String]
    }

    final class AdaptiveClaimSnapshotCodePrefixRule: AdaptiveClaimSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveClaimSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveClaimSnapshotNameLengthRule: AdaptiveClaimSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClaimSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClaimSnapshotCodeLengthRule: AdaptiveClaimSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClaimSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClaimSnapshotStartsAtRangeRule: AdaptiveClaimSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveClaimSnapshot) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveClaimSnapshotRequiredNameRule: AdaptiveClaimSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveClaimSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive claim snapshot.
    final class AdaptiveClaimSnapshotValidator {
        var rules: [any AdaptiveClaimSnapshotRule]

        init(rules: [any AdaptiveClaimSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveClaimSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveClaimSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveClaimSnapshot]) -> [String: [String]] {
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

    static func defaultAdaptiveClaimSnapshotValidator() -> AdaptiveClaimSnapshotValidator {
        return AdaptiveClaimSnapshotValidator(
            rules: [
                AdaptiveClaimSnapshotCodePrefixRule(prefix: "OPS"),
                AdaptiveClaimSnapshotNameLengthRule(maxLength: 32),
                AdaptiveClaimSnapshotCodeLengthRule(maxLength: 3600),
                AdaptiveClaimSnapshotStartsAtRangeRule(min: 1000, max: 86400),
                AdaptiveClaimSnapshotRequiredNameRule(message: "adaptive claim snapshot needs a value"),
            ]
        )
    }
}
