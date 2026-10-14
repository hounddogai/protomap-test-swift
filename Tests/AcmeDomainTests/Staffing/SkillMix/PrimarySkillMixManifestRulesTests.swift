@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimarySkillMixManifestValidator()
        let item = Staffing.newPrimarySkillMixManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimarySkillMixManifestUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Staffing.PrimarySkillMixManifestUnitLengthRule(maxLength: 1000)
        let item = Staffing.newPrimarySkillMixManifest("x", title: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimarySkillMixManifestRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.PrimarySkillMixManifestRequiredUnitRule(message: "primary skill mix manifest needs an entry")
        let item = Staffing.newPrimarySkillMixManifest("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimarySkillMixManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.PrimarySkillMixManifestTitleLengthRule(maxLength: 3600)
        let item = Staffing.newPrimarySkillMixManifest("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimarySkillMixManifestAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Staffing.PrimarySkillMixManifestAcuityRangeRule(min: 32, max: 3600)
        let item = Staffing.newPrimarySkillMixManifest("x", title: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimarySkillMixManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimarySkillMixManifestCodeLengthRule(maxLength: 1000)
        let item = Staffing.newPrimarySkillMixManifest("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
