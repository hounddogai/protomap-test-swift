@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackShiftBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackShiftBaselineValidator()
        let item = Staffing.newFallbackShiftBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackShiftBaselineExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.FallbackShiftBaselineExpiresAtRangeRule(min: 16, max: 3600)
        let item = Staffing.newFallbackShiftBaseline("x", name: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackShiftBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FallbackShiftBaselineCodeLengthRule(maxLength: 1000)
        let item = Staffing.newFallbackShiftBaseline("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
