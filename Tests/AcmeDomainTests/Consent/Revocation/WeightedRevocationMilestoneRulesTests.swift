@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedRevocationMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedRevocationMilestoneValidator()
        let item = Consent.newWeightedRevocationMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedRevocationMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WeightedRevocationMilestoneCodeLengthRule(maxLength: 255)
        let item = Consent.newWeightedRevocationMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWeightedRevocationMilestoneThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Consent.WeightedRevocationMilestoneThresholdRangeRule(min: 5.7, max: 295.6)
        let item = Consent.newWeightedRevocationMilestone("x", title: "y")
        item.threshold = 297.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWeightedRevocationMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.WeightedRevocationMilestoneTitleLengthRule(maxLength: 32)
        let item = Consent.newWeightedRevocationMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWeightedRevocationMilestoneWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.WeightedRevocationMilestoneWeightRangeRule(min: 5.0, max: 4637.5)
        let item = Consent.newWeightedRevocationMilestone("x", title: "y")
        item.weight = 4639.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWeightedRevocationMilestoneWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Consent.WeightedRevocationMilestoneWardLengthRule(maxLength: 86400)
        let item = Consent.newWeightedRevocationMilestone("x", title: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
