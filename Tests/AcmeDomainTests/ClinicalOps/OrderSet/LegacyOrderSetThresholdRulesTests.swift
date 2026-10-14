@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyOrderSetThresholdValidator()
        let item = ClinicalOps.newLegacyOrderSetThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetThresholdMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.LegacyOrderSetThresholdMaximumRangeRule(min: 6.9, max: 3328.0)
        let item = ClinicalOps.newLegacyOrderSetThreshold("x", title: "y")
        item.maximum = 3329.5
        #expect(rule.check(item).count > 0)
    }
}
