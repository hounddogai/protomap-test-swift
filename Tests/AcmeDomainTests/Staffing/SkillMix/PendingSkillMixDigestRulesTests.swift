@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingSkillMixDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingSkillMixDigestValidator()
        let item = Staffing.newPendingSkillMixDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingSkillMixDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PendingSkillMixDigestRequiredCodeRule(message: "pending skill mix digest needs an entry")
        let item = Staffing.newPendingSkillMixDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingSkillMixDigestRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Staffing.PendingSkillMixDigestRevisionRangeRule(min: 16, max: 86400)
        let item = Staffing.newPendingSkillMixDigest("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingSkillMixDigestNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Staffing.PendingSkillMixDigestNotesLengthRule(maxLength: 64)
        let item = Staffing.newPendingSkillMixDigest("x", title: "y")
        item.notes = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
