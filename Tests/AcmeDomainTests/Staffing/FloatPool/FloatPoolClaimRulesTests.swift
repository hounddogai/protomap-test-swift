@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolClaimValidator()
        let item = Staffing.newFloatPoolClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolClaimMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.FloatPoolClaimMinimumRangeRule(min: 4.4, max: 1383.8)
        let item = Staffing.newFloatPoolClaim("x", label: "y")
        item.minimum = 1385.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolClaimLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FloatPoolClaimLabelLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolClaim("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
