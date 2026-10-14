import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census bundle must pass. Check returns its problems, or none.
    protocol CensusBundleRule {
        func check(_ item: CensusBundle) -> [String]
    }

    final class CensusBundleTitleLengthRule: CensusBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusBundleAllowedFacilityRule: CensusBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is stale"]
            }
            return []
        }
    }

    final class CensusBundleCodePrefixRule: CensusBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusBundleRequiredChannelRule: CensusBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusBundle) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census bundle.
    final class CensusBundleValidator {
        var rules: [any CensusBundleRule]

        init(rules: [any CensusBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusBundle]) -> [String: [String]] {
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

    static func defaultCensusBundleValidator() -> CensusBundleValidator {
        return CensusBundleValidator(
            rules: [
                CensusBundleTitleLengthRule(maxLength: 1000),
                CensusBundleAllowedFacilityRule(allowed: ["batched", "batched"]),
                CensusBundleCodePrefixRule(prefix: "X"),
                CensusBundleRequiredChannelRule(message: "census bundle needs a value"),
            ]
        )
    }
}
