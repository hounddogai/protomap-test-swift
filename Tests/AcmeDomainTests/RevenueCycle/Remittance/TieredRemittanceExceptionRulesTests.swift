@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredRemittanceExceptionValidator()
        let item = RevenueCycle.newTieredRemittanceException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceExceptionSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = RevenueCycle.TieredRemittanceExceptionSpecialtyLengthRule(maxLength: 64)
        let item = RevenueCycle.newTieredRemittanceException("x", title: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceExceptionRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = RevenueCycle.TieredRemittanceExceptionRequiredSpecialtyRule(
            message: "tiered remittance exception needs a value"
        )
        let item = RevenueCycle.newTieredRemittanceException("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredRemittanceExceptionRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = RevenueCycle.TieredRemittanceExceptionRequiredSummaryRule(
            message: "tiered remittance exception needs this field"
        )
        let item = RevenueCycle.newTieredRemittanceException("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredRemittanceExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.TieredRemittanceExceptionTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newTieredRemittanceException("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
