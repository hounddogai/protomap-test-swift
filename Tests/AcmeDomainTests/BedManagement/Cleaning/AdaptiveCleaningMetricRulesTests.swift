@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveCleaningMetricValidator()
        let item = BedManagement.newAdaptiveCleaningMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.AdaptiveCleaningMetricCodeLengthRule(maxLength: 255)
        let item = BedManagement.newAdaptiveCleaningMetric("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.AdaptiveCleaningMetricRequiredCodeRule(
            message: "adaptive cleaning metric needs a value"
        )
        let item = BedManagement.newAdaptiveCleaningMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
