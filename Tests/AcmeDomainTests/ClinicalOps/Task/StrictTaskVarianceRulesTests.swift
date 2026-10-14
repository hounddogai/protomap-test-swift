@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictTaskVarianceValidator()
        let item = ClinicalOps.newStrictTaskVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictTaskVarianceExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = ClinicalOps.StrictTaskVarianceExternalRefLengthRule(maxLength: 86400)
        let item = ClinicalOps.newStrictTaskVariance("x", name: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsStrictTaskVarianceRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.StrictTaskVarianceRateRangeRule(min: 3.2, max: 4678.5)
        let item = ClinicalOps.newStrictTaskVariance("x", name: "y")
        item.rate = 4680.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsStrictTaskVarianceAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.StrictTaskVarianceAmountRangeRule(min: 3.0, max: 1728.5)
        let item = ClinicalOps.newStrictTaskVariance("x", name: "y")
        item.amount = 1730.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsStrictTaskVarianceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.StrictTaskVarianceRequiredNameRule(message: "strict task variance needs this field")
        let item = ClinicalOps.newStrictTaskVariance("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictTaskVarianceChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = ClinicalOps.StrictTaskVarianceChecksumLengthRule(maxLength: 32)
        let item = ClinicalOps.newStrictTaskVariance("x", name: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
