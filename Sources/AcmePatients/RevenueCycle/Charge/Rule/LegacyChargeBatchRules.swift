import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy charge batch must pass. Check returns its problems, or none.
    protocol LegacyChargeBatchRule {
        func check(_ item: LegacyChargeBatch) -> [String]
    }

    final class LegacyChargeBatchRegionLengthRule: LegacyChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyChargeBatch) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyChargeBatchRequiredNameRule: LegacyChargeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyChargeBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyChargeBatchAllowedRegionRule: LegacyChargeBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyChargeBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is stale"]
            }
            return []
        }
    }

    final class LegacyChargeBatchCodePrefixRule: LegacyChargeBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyChargeBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyChargeBatchRequiredRegionRule: LegacyChargeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyChargeBatch) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy charge batch.
    final class LegacyChargeBatchValidator {
        var rules: [any LegacyChargeBatchRule]

        init(rules: [any LegacyChargeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyChargeBatch) -> [String] {
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

        func requireValid(_ item: LegacyChargeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyChargeBatch]) -> [String: [String]] {
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

    static func defaultLegacyChargeBatchValidator() -> LegacyChargeBatchValidator {
        return LegacyChargeBatchValidator(
            rules: [
                LegacyChargeBatchRegionLengthRule(maxLength: 3600),
                LegacyChargeBatchRequiredNameRule(message: "legacy charge batch needs a value"),
                LegacyChargeBatchAllowedRegionRule(allowed: ["global"]),
                LegacyChargeBatchCodePrefixRule(prefix: "OPS"),
                LegacyChargeBatchRequiredRegionRule(message: "legacy charge batch needs this field"),
            ]
        )
    }
}
