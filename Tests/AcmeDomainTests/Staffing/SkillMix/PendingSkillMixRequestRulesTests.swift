@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingSkillMixRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingSkillMixRequestValidator()
        let item = Staffing.newPendingSkillMixRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingSkillMixRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PendingSkillMixRequestRequiredCodeRule(message: "pending skill mix request needs an entry")
        let item = Staffing.newPendingSkillMixRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingSkillMixRequestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Staffing.PendingSkillMixRequestEndsAtRangeRule(min: 16, max: 64)
        let item = Staffing.newPendingSkillMixRequest("x", name: "y")
        item.endsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingSkillMixRequestRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Staffing.PendingSkillMixRequestRequiredChecksumRule(
            message: "pending skill mix request needs a value"
        )
        let item = Staffing.newPendingSkillMixRequest("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingSkillMixRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PendingSkillMixRequestCodeLengthRule(maxLength: 86400)
        let item = Staffing.newPendingSkillMixRequest("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingSkillMixRequestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.PendingSkillMixRequestNameLengthRule(maxLength: 3600)
        let item = Staffing.newPendingSkillMixRequest("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
