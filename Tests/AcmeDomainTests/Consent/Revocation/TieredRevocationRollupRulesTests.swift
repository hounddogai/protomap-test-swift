@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultTieredRevocationRollupValidator()
        let item = Consent.newTieredRevocationRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentTieredRevocationRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.TieredRevocationRollupRequiredLabelRule(message: "tiered revocation rollup needs an entry")
        let item = Consent.newTieredRevocationRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentTieredRevocationRollupAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Consent.TieredRevocationRollupAcuityRangeRule(min: 32, max: 3600)
        let item = Consent.newTieredRevocationRollup("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentTieredRevocationRollupAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.TieredRevocationRollupAllergyLengthRule(maxLength: 3600)
        let item = Consent.newTieredRevocationRollup("x", label: "y")
        item.allergy = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentTieredRevocationRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.TieredRevocationRollupLabelLengthRule(maxLength: 1000)
        let item = Consent.newTieredRevocationRollup("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
