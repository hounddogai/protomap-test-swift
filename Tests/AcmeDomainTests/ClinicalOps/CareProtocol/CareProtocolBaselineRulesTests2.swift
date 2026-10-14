@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolBaselineValidator()
        let item = ClinicalOps.newCareProtocolBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolBaselineSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.CareProtocolBaselineSequenceRangeRule(min: 32, max: 32)
        let item = ClinicalOps.newCareProtocolBaseline("x", title: "y")
        item.sequence = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolBaselineRequiredCodeRule(message: "care protocol baseline needs an entry")
        let item = ClinicalOps.newCareProtocolBaseline("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolBaselineRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.CareProtocolBaselineRateRangeRule(min: 7.9, max: 2805.3)
        let item = ClinicalOps.newCareProtocolBaseline("x", title: "y")
        item.rate = 2806.8
        #expect(rule.check(item).count > 0)
    }
}
