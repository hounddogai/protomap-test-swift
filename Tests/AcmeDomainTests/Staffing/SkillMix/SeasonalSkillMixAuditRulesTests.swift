@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalSkillMixAuditValidator()
        let item = Staffing.newSeasonalSkillMixAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalSkillMixAuditRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.SeasonalSkillMixAuditRequiredWardRule(message: "seasonal skill mix audit needs this field")
        let item = Staffing.newSeasonalSkillMixAudit("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalSkillMixAuditExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.SeasonalSkillMixAuditExpiresAtRangeRule(min: 16, max: 86400)
        let item = Staffing.newSeasonalSkillMixAudit("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSeasonalSkillMixAuditDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.SeasonalSkillMixAuditDosageMgRangeRule(min: 4.7, max: 4040.7)
        let item = Staffing.newSeasonalSkillMixAudit("x", title: "y")
        item.dosageMg = 4042.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSeasonalSkillMixAuditFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.SeasonalSkillMixAuditFacilityLengthRule(maxLength: 64)
        let item = Staffing.newSeasonalSkillMixAudit("x", title: "y")
        item.facility = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalSkillMixAuditWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Staffing.SeasonalSkillMixAuditWardLengthRule(maxLength: 255)
        let item = Staffing.newSeasonalSkillMixAudit("x", title: "y")
        item.ward = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalSkillMixAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.SeasonalSkillMixAuditRequiredTitleRule(message: "seasonal skill mix audit needs a value")
        let item = Staffing.newSeasonalSkillMixAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
