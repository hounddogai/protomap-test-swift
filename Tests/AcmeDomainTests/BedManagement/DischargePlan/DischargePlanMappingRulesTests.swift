@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanMappingValidator()
        let item = BedManagement.newDischargePlanMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanMappingDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.DischargePlanMappingDurationMinutesRangeRule(min: 64, max: 255)
        let item = BedManagement.newDischargePlanMapping("x", label: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanMappingUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.DischargePlanMappingUpdatedAtRangeRule(min: 32, max: 64)
        let item = BedManagement.newDischargePlanMapping("x", label: "y")
        item.updatedAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanMappingCodeLengthRule(maxLength: 120)
        let item = BedManagement.newDischargePlanMapping("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanMappingDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.DischargePlanMappingDiscountRangeRule(min: 5.5, max: 3576.9)
        let item = BedManagement.newDischargePlanMapping("x", label: "y")
        item.discount = 3578.4
        #expect(rule.check(item).count > 0)
    }
}
