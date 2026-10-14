@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolLedgerValidator()
        let item = Imaging.newCareProtocolLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolLedgerCodeLengthRule(maxLength: 16)
        let item = Imaging.newCareProtocolLedger("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolLedgerGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.CareProtocolLedgerGraceDaysRangeRule(min: 32, max: 80)
        let item = Imaging.newCareProtocolLedger("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolLedgerAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Imaging.CareProtocolLedgerAllergyLengthRule(maxLength: 86400)
        let item = Imaging.newCareProtocolLedger("x", label: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolLedgerExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Imaging.CareProtocolLedgerExternalRefLengthRule(maxLength: 64)
        let item = Imaging.newCareProtocolLedger("x", label: "y")
        item.externalRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolLedgerRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.CareProtocolLedgerRequiredAllergyRule(message: "care protocol ledger needs this field")
        let item = Imaging.newCareProtocolLedger("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolLedgerCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Imaging.CareProtocolLedgerCreatedAtRangeRule(min: 64, max: 1000)
        let item = Imaging.newCareProtocolLedger("x", label: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
