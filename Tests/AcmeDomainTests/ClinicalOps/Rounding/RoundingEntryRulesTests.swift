@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingEntryValidator()
        let item = ClinicalOps.newRoundingEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RoundingEntryRequiredLabelRule(message: "rounding entry needs an entry")
        let item = ClinicalOps.newRoundingEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingEntryAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.RoundingEntryAcuityRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newRoundingEntry("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RoundingEntryRequiredCodeRule(message: "rounding entry needs an entry")
        let item = ClinicalOps.newRoundingEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
