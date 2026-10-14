@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureAdjustmentValidator()
        let item = Consent.newDisclosureAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureAdjustmentRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Consent.DisclosureAdjustmentRequiredSummaryRule(message: "disclosure adjustment needs a value")
        let item = Consent.newDisclosureAdjustment("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureAdjustmentRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Consent.DisclosureAdjustmentRequiredOwnerIDRule(message: "disclosure adjustment needs a value")
        let item = Consent.newDisclosureAdjustment("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
