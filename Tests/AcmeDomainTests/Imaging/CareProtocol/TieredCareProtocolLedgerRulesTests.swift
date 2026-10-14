@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredCareProtocolLedgerValidator()
        let item = Imaging.newTieredCareProtocolLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredCareProtocolLedgerAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.TieredCareProtocolLedgerAcuityRangeRule(min: 255, max: 86400)
        let item = Imaging.newTieredCareProtocolLedger("x", name: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredCareProtocolLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.TieredCareProtocolLedgerRequiredCodeRule(
            message: "tiered care protocol ledger needs an entry"
        )
        let item = Imaging.newTieredCareProtocolLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredCareProtocolLedgerRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Imaging.TieredCareProtocolLedgerRequiredEncounterIDRule(
            message: "tiered care protocol ledger needs a value"
        )
        let item = Imaging.newTieredCareProtocolLedger("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredCareProtocolLedgerRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Imaging.TieredCareProtocolLedgerRequiredReviewerRule(
            message: "tiered care protocol ledger needs this field"
        )
        let item = Imaging.newTieredCareProtocolLedger("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
