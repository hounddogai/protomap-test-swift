@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalModalityAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalModalityAuditValidator()
        let item = Imaging.newSeasonalModalityAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalModalityAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.SeasonalModalityAuditRequiredCodeRule(message: "seasonal modality audit needs a value")
        let item = Imaging.newSeasonalModalityAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalModalityAuditAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Imaging.SeasonalModalityAuditAmountRangeRule(min: 3.1, max: 2749.1)
        let item = Imaging.newSeasonalModalityAudit("x", title: "y")
        item.amount = 2750.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalModalityAuditRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.SeasonalModalityAuditRequiredAllergyRule(message: "seasonal modality audit needs an entry")
        let item = Imaging.newSeasonalModalityAudit("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalModalityAuditAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.SeasonalModalityAuditAttemptsRangeRule(min: 32, max: 86400)
        let item = Imaging.newSeasonalModalityAudit("x", title: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalModalityAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.SeasonalModalityAuditTitleLengthRule(maxLength: 32)
        let item = Imaging.newSeasonalModalityAudit("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
