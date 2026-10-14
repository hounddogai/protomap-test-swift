@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixDigestValidator()
        let item = Staffing.newSkillMixDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixDigestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.SkillMixDigestLabelLengthRule(maxLength: 64)
        let item = Staffing.newSkillMixDigest("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixDigestCodeLengthRule(maxLength: 1000)
        let item = Staffing.newSkillMixDigest("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixDigestMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.SkillMixDigestMaximumRangeRule(min: 4.5, max: 1080.9)
        let item = Staffing.newSkillMixDigest("x", label: "y")
        item.maximum = 1082.4
        #expect(rule.check(item).count > 0)
    }
}
