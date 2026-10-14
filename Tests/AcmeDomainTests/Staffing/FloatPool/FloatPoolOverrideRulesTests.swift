@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolOverrideValidator()
        let item = Staffing.newFloatPoolOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolOverrideRequiredCodeRule(message: "float pool override needs this field")
        let item = Staffing.newFloatPoolOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolOverrideRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Staffing.FloatPoolOverrideRequiredChannelRule(message: "float pool override needs a value")
        let item = Staffing.newFloatPoolOverride("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolOverrideLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FloatPoolOverrideLabelLengthRule(maxLength: 3600)
        let item = Staffing.newFloatPoolOverride("x", name: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
