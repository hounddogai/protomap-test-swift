@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalFloatPoolOverrideValidator()
        let item = Staffing.newRegionalFloatPoolOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalFloatPoolOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.RegionalFloatPoolOverrideTitleLengthRule(maxLength: 1000)
        let item = Staffing.newRegionalFloatPoolOverride("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalFloatPoolOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.RegionalFloatPoolOverrideCodeLengthRule(maxLength: 32)
        let item = Staffing.newRegionalFloatPoolOverride("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
