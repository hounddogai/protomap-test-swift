import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered authorization cycle must pass. Check returns its problems, or none.
    protocol TieredAuthorizationCycleRule {
        func check(_ item: TieredAuthorizationCycle) -> [String]
    }

    final class TieredAuthorizationCycleRequiredNameRule: TieredAuthorizationCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAuthorizationCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAuthorizationCycleCodePrefixRule: TieredAuthorizationCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredAuthorizationCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredAuthorizationCycleAllowedSegmentRule: TieredAuthorizationCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredAuthorizationCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is unknown"]
            }
            return []
        }
    }

    final class TieredAuthorizationCycleRequiredFacilityRule: TieredAuthorizationCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAuthorizationCycle) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAuthorizationCycleNameLengthRule: TieredAuthorizationCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAuthorizationCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAuthorizationCycleRequiredCodeRule: TieredAuthorizationCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAuthorizationCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered authorization cycle.
    final class TieredAuthorizationCycleValidator {
        var rules: [any TieredAuthorizationCycleRule]

        init(rules: [any TieredAuthorizationCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAuthorizationCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredAuthorizationCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAuthorizationCycle]) -> [String: [String]] {
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

    static func defaultTieredAuthorizationCycleValidator() -> TieredAuthorizationCycleValidator {
        return TieredAuthorizationCycleValidator(
            rules: [
                TieredAuthorizationCycleRequiredNameRule(message: "tiered authorization cycle needs this field"),
                TieredAuthorizationCycleCodePrefixRule(prefix: "OPS"),
                TieredAuthorizationCycleAllowedSegmentRule(allowed: ["strict", "global"]),
                TieredAuthorizationCycleRequiredFacilityRule(message: "tiered authorization cycle needs a value"),
                TieredAuthorizationCycleNameLengthRule(maxLength: 3600),
                TieredAuthorizationCycleRequiredCodeRule(message: "tiered authorization cycle needs this field"),
            ]
        )
    }
}
