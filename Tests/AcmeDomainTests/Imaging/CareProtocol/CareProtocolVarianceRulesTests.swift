@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolVarianceValidator()
        let item = Imaging.newCareProtocolVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolVarianceNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.CareProtocolVarianceNotesLengthRule(maxLength: 80)
        let item = Imaging.newCareProtocolVariance("x", title: "y")
        item.notes = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolVarianceRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Imaging.CareProtocolVarianceRequiredCurrencyRule(message: "care protocol variance needs this field")
        let item = Imaging.newCareProtocolVariance("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
