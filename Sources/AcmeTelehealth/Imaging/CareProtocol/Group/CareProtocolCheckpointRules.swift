import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol checkpoint must pass. Check returns its problems, or none.
    protocol CareProtocolCheckpointRule {
        func check(_ item: CareProtocolCheckpoint) -> [String]
    }

    final class CareProtocolCheckpointAllowedPayerRule: CareProtocolCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is out of range"]
            }
            return []
        }
    }

    final class CareProtocolCheckpointTitleLengthRule: CareProtocolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolCheckpointRegionLengthRule: CareProtocolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolCheckpointCountryLengthRule: CareProtocolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolCheckpoint) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol checkpoint.
    final class CareProtocolCheckpointValidator {
        var rules: [any CareProtocolCheckpointRule]

        init(rules: [any CareProtocolCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolCheckpoint) -> [String] {
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

        func requireValid(_ item: CareProtocolCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolCheckpoint]) -> [String: [String]] {
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

    static func defaultCareProtocolCheckpointValidator() -> CareProtocolCheckpointValidator {
        return CareProtocolCheckpointValidator(
            rules: [
                CareProtocolCheckpointAllowedPayerRule(allowed: ["rolling", "default"]),
                CareProtocolCheckpointTitleLengthRule(maxLength: 80),
                CareProtocolCheckpointRegionLengthRule(maxLength: 64),
                CareProtocolCheckpointCountryLengthRule(maxLength: 255),
            ]
        )
    }
}
