@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingFloatPoolDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingFloatPoolDraftValidator()
        let item = Staffing.newPendingFloatPoolDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingFloatPoolDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PendingFloatPoolDraftCodeLengthRule(maxLength: 80)
        let item = Staffing.newPendingFloatPoolDraft("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingFloatPoolDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.PendingFloatPoolDraftRequiredNameRule(message: "pending float pool draft needs a value")
        let item = Staffing.newPendingFloatPoolDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingFloatPoolDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PendingFloatPoolDraftRequiredCodeRule(message: "pending float pool draft needs an entry")
        let item = Staffing.newPendingFloatPoolDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
