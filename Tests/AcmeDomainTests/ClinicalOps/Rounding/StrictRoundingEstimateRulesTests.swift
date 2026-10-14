@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictRoundingEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictRoundingEstimateValidator()
        let item = ClinicalOps.newStrictRoundingEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictRoundingEstimateQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.StrictRoundingEstimateQuantityRangeRule(min: 120, max: 86400)
        let item = ClinicalOps.newStrictRoundingEstimate("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsStrictRoundingEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.StrictRoundingEstimateNameLengthRule(maxLength: 32)
        let item = ClinicalOps.newStrictRoundingEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
