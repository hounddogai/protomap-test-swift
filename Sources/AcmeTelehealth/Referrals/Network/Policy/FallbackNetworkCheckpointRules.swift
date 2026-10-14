import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback network checkpoint must pass. Check returns its problems, or none.
    protocol FallbackNetworkCheckpointRule {
        func check(_ item: FallbackNetworkCheckpoint) -> [String]
    }

    final class FallbackNetworkCheckpointRegionLengthRule: FallbackNetworkCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackNetworkCheckpoint) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackNetworkCheckpointCodeLengthRule: FallbackNetworkCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackNetworkCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackNetworkCheckpointAllowedRegionRule: FallbackNetworkCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackNetworkCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is unknown"]
            }
            return []
        }
    }

    final class FallbackNetworkCheckpointRequiredPatientRefRule: FallbackNetworkCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackNetworkCheckpoint) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback network checkpoint.
    final class FallbackNetworkCheckpointValidator {
        var rules: [any FallbackNetworkCheckpointRule]

        init(rules: [any FallbackNetworkCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackNetworkCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackNetworkCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackNetworkCheckpoint]) -> [String: [String]] {
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

    static func defaultFallbackNetworkCheckpointValidator() -> FallbackNetworkCheckpointValidator {
        return FallbackNetworkCheckpointValidator(
            rules: [
                FallbackNetworkCheckpointRegionLengthRule(maxLength: 120),
                FallbackNetworkCheckpointCodeLengthRule(maxLength: 255),
                FallbackNetworkCheckpointAllowedRegionRule(allowed: ["batched"]),
                FallbackNetworkCheckpointRequiredPatientRefRule(message: "fallback network checkpoint needs a value"),
            ]
        )
    }
}
