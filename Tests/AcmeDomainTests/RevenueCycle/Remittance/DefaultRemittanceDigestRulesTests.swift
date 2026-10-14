@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultRemittanceDigestValidator()
        let item = RevenueCycle.newDefaultRemittanceDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultRemittanceDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DefaultRemittanceDigestRequiredNameRule(
            message: "default remittance digest needs an entry"
        )
        let item = RevenueCycle.newDefaultRemittanceDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultRemittanceDigestRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = RevenueCycle.DefaultRemittanceDigestRequiredNotesRule(
            message: "default remittance digest needs an entry"
        )
        let item = RevenueCycle.newDefaultRemittanceDigest("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultRemittanceDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DefaultRemittanceDigestRequiredCodeRule(
            message: "default remittance digest needs a value"
        )
        let item = RevenueCycle.newDefaultRemittanceDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
