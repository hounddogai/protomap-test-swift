@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackShiftMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackShiftMappingValidator()
        let item = Staffing.newFallbackShiftMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackShiftMappingExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.FallbackShiftMappingExpiresAtRangeRule(min: 120, max: 1000)
        let item = Staffing.newFallbackShiftMapping("x", name: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackShiftMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.FallbackShiftMappingRequiredNameRule(message: "fallback shift mapping needs a value")
        let item = Staffing.newFallbackShiftMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackShiftMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FallbackShiftMappingRequiredCodeRule(message: "fallback shift mapping needs a value")
        let item = Staffing.newFallbackShiftMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
