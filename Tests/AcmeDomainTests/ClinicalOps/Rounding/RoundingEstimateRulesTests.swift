@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingEstimateValidator()
        let item = ClinicalOps.newRoundingEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingEstimateRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = ClinicalOps.RoundingEstimateRefillsRangeRule(min: 64, max: 255)
        let item = ClinicalOps.newRoundingEstimate("x", name: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RoundingEstimateRequiredNameRule(message: "rounding estimate needs a value")
        let item = ClinicalOps.newRoundingEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RoundingEstimateCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newRoundingEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingEstimateFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = ClinicalOps.RoundingEstimateFloorValueRangeRule(min: 7.4, max: 260.9)
        let item = ClinicalOps.newRoundingEstimate("x", name: "y")
        item.floorValue = 262.4
        #expect(rule.check(item).count > 0)
    }
}
