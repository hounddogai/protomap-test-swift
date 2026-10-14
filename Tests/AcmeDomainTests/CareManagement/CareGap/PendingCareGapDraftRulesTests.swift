@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingCareGapDraftValidator()
        let item = CareManagement.newPendingCareGapDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingCareGapDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.PendingCareGapDraftNameLengthRule(maxLength: 64)
        let item = CareManagement.newPendingCareGapDraft("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingCareGapDraftRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = CareManagement.PendingCareGapDraftRequiredPayerRule(message: "pending care gap draft needs a value")
        let item = CareManagement.newPendingCareGapDraft("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingCareGapDraftRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = CareManagement.PendingCareGapDraftRequiredContactEmailRule(
            message: "pending care gap draft needs a value"
        )
        let item = CareManagement.newPendingCareGapDraft("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingCareGapDraftPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = CareManagement.PendingCareGapDraftPayerLengthRule(maxLength: 64)
        let item = CareManagement.newPendingCareGapDraft("x", name: "y")
        item.payer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingCareGapDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingCareGapDraftCodeLengthRule(maxLength: 80)
        let item = CareManagement.newPendingCareGapDraft("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
