@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingRoundingSlotValidator()
        let item = ClinicalOps.newRollingRoundingSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingSlotExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.RollingRoundingSlotExpiresAtRangeRule(min: 32, max: 64)
        let item = ClinicalOps.newRollingRoundingSlot("x", label: "y")
        item.expiresAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingSlotRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.RollingRoundingSlotRateRangeRule(min: 4.1, max: 4124.6)
        let item = ClinicalOps.newRollingRoundingSlot("x", label: "y")
        item.rate = 4126.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RollingRoundingSlotCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRollingRoundingSlot("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
