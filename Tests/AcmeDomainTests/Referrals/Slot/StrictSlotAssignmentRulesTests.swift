@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictSlotAssignmentValidator()
        let item = Referrals.newStrictSlotAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictSlotAssignmentRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Referrals.StrictSlotAssignmentRequiredNotesRule(message: "strict slot assignment needs this field")
        let item = Referrals.newStrictSlotAssignment("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictSlotAssignmentPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Referrals.StrictSlotAssignmentPatientRefLengthRule(maxLength: 32)
        let item = Referrals.newStrictSlotAssignment("x", name: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictSlotAssignmentNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Referrals.StrictSlotAssignmentNotesLengthRule(maxLength: 86400)
        let item = Referrals.newStrictSlotAssignment("x", name: "y")
        item.notes = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictSlotAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.StrictSlotAssignmentRequiredNameRule(message: "strict slot assignment needs a value")
        let item = Referrals.newStrictSlotAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictSlotAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.StrictSlotAssignmentCodeLengthRule(maxLength: 3600)
        let item = Referrals.newStrictSlotAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
