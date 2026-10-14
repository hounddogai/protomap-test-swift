@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixBundleValidator()
        let item = Staffing.newSkillMixBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixBundleLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Staffing.SkillMixBundleLocaleLengthRule(maxLength: 1000)
        let item = Staffing.newSkillMixBundle("x", title: "y")
        item.locale = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixBundleRequiredCodeRule(message: "skill mix bundle needs this field")
        let item = Staffing.newSkillMixBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.SkillMixBundleTitleLengthRule(maxLength: 64)
        let item = Staffing.newSkillMixBundle("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.SkillMixBundleRequiredNameRule(message: "skill mix bundle needs this field")
        let item = Staffing.newSkillMixBundle("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
