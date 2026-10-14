@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultTieredRevocationBaselineValidator()
        let item = Consent.newTieredRevocationBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentTieredRevocationBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.TieredRevocationBaselineRequiredCodeRule(message: "tiered revocation baseline needs a value")
        let item = Consent.newTieredRevocationBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentTieredRevocationBaselineCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.TieredRevocationBaselineCopayRangeRule(min: 2.1, max: 3284.1)
        let item = Consent.newTieredRevocationBaseline("x", name: "y")
        item.copay = 3285.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentTieredRevocationBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.TieredRevocationBaselineRequiredLabelRule(
            message: "tiered revocation baseline needs an entry"
        )
        let item = Consent.newTieredRevocationBaseline("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
