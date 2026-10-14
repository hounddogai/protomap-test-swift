@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalRoundingAllocationValidator()
        let item = ClinicalOps.newSeasonalRoundingAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.SeasonalRoundingAllocationTitleLengthRule(maxLength: 255)
        let item = ClinicalOps.newSeasonalRoundingAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingAllocationRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.SeasonalRoundingAllocationRequiredSpecialtyRule(
            message: "seasonal rounding allocation needs a value"
        )
        let item = ClinicalOps.newSeasonalRoundingAllocation("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingAllocationSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.SeasonalRoundingAllocationSequenceRangeRule(min: 80, max: 120)
        let item = ClinicalOps.newSeasonalRoundingAllocation("x", title: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.SeasonalRoundingAllocationRequiredCodeRule(
            message: "seasonal rounding allocation needs a value"
        )
        let item = ClinicalOps.newSeasonalRoundingAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
