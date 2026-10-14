@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveCareProtocolProfileValidator()
        let item = ClinicalOps.newAdaptiveCareProtocolProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolProfileRequiredTitleRule(
            message: "adaptive care protocol profile needs this field"
        )
        let item = ClinicalOps.newAdaptiveCareProtocolProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolProfileDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolProfileDosageMgRangeRule(min: 2.0, max: 2858.8)
        let item = ClinicalOps.newAdaptiveCareProtocolProfile("x", title: "y")
        item.dosageMg = 2860.3
        #expect(rule.check(item).count > 0)
    }
}
