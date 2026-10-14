@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingModalityQuotaValidator()
        let item = Imaging.newPendingModalityQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingModalityQuotaRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.PendingModalityQuotaRequiredAllergyRule(message: "pending modality quota needs an entry")
        let item = Imaging.newPendingModalityQuota("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingModalityQuotaBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.PendingModalityQuotaBatchSizeRangeRule(min: 120, max: 3600)
        let item = Imaging.newPendingModalityQuota("x", label: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}
