import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy recall record must pass. Check returns its problems, or none.
    protocol LegacyRecallRecordRule {
        func check(_ item: LegacyRecallRecord) -> [String]
    }

    final class LegacyRecallRecordRequiredCodeRule: LegacyRecallRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRecallRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRecallRecordAllowedTitleRule: LegacyRecallRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyRecallRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is unknown"]
            }
            return []
        }
    }

    final class LegacyRecallRecordChannelLengthRule: LegacyRecallRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallRecord) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRecallRecordRegionLengthRule: LegacyRecallRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallRecord) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy recall record.
    final class LegacyRecallRecordValidator {
        var rules: [any LegacyRecallRecordRule]

        init(rules: [any LegacyRecallRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRecallRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyRecallRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRecallRecord]) -> [String: [String]] {
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

    static func defaultLegacyRecallRecordValidator() -> LegacyRecallRecordValidator {
        return LegacyRecallRecordValidator(
            rules: [
                LegacyRecallRecordRequiredCodeRule(message: "legacy recall record needs an entry"),
                LegacyRecallRecordAllowedTitleRule(allowed: ["tiered", "manual"]),
                LegacyRecallRecordChannelLengthRule(maxLength: 120),
                LegacyRecallRecordRegionLengthRule(maxLength: 3600),
            ]
        )
    }
}
