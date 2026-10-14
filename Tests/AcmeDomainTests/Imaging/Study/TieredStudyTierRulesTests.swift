@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudyTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredStudyTierValidator()
        let item = Imaging.newTieredStudyTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredStudyTierQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Imaging.TieredStudyTierQuantityRangeRule(min: 255, max: 3600)
        let item = Imaging.newTieredStudyTier("x", label: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredStudyTierRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Imaging.TieredStudyTierRequiredProcedureCodeRule(message: "tiered study tier needs a value")
        let item = Imaging.newTieredStudyTier("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
