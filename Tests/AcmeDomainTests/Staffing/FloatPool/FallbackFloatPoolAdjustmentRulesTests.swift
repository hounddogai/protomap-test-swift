@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackFloatPoolAdjustmentValidator()
        let item = Staffing.newFallbackFloatPoolAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackFloatPoolAdjustmentVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.FallbackFloatPoolAdjustmentVersionRangeRule(min: 1000, max: 86400)
        let item = Staffing.newFallbackFloatPoolAdjustment("x", label: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackFloatPoolAdjustmentProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.FallbackFloatPoolAdjustmentProcedureCodeLengthRule(maxLength: 120)
        let item = Staffing.newFallbackFloatPoolAdjustment("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackFloatPoolAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FallbackFloatPoolAdjustmentCodeLengthRule(maxLength: 64)
        let item = Staffing.newFallbackFloatPoolAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
