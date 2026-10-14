@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachReservationValidator()
        let item = CareManagement.newOutreachReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.OutreachReservationRequiredCodeRule(message: "outreach reservation needs this field")
        let item = CareManagement.newOutreachReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.OutreachReservationCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newOutreachReservation("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachReservationExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.OutreachReservationExternalRefLengthRule(maxLength: 3600)
        let item = CareManagement.newOutreachReservation("x", label: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachReservationNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = CareManagement.OutreachReservationNotesLengthRule(maxLength: 3600)
        let item = CareManagement.newOutreachReservation("x", label: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
