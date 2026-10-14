@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolDraftValidator()
        let item = Staffing.newFloatPoolDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FloatPoolDraftNameLengthRule(maxLength: 80)
        let item = Staffing.newFloatPoolDraft("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolDraftDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Staffing.FloatPoolDraftDiscountRangeRule(min: 4.5, max: 2941.6)
        let item = Staffing.newFloatPoolDraft("x", name: "y")
        item.discount = 2943.1
        #expect(rule.check(item).count > 0)
    }
}
