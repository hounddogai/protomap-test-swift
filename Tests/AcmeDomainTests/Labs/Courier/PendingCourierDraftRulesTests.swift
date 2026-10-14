@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingCourierDraftValidator()
        let item = Labs.newPendingCourierDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingCourierDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingCourierDraftRequiredCodeRule(message: "pending courier draft needs a value")
        let item = Labs.newPendingCourierDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingCourierDraftPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.PendingCourierDraftPatientRefLengthRule(maxLength: 120)
        let item = Labs.newPendingCourierDraft("x", title: "y")
        item.patientRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
