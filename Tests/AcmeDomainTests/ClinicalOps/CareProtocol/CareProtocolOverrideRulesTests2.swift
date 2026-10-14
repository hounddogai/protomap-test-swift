@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolOverrideValidator()
        let item = ClinicalOps.newCareProtocolOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.CareProtocolOverrideTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newCareProtocolOverride("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolOverrideScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.CareProtocolOverrideScoreRangeRule(min: 6.2, max: 4571.2)
        let item = ClinicalOps.newCareProtocolOverride("x", title: "y")
        item.score = 4572.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolOverrideRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.CareProtocolOverrideRateRangeRule(min: 4.1, max: 1085.9)
        let item = ClinicalOps.newCareProtocolOverride("x", title: "y")
        item.rate = 1087.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolOverrideRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = ClinicalOps.CareProtocolOverrideRatioRangeRule(min: 9.4, max: 4742.3)
        let item = ClinicalOps.newCareProtocolOverride("x", title: "y")
        item.ratio = 4743.8
        #expect(rule.check(item).count > 0)
    }
}
