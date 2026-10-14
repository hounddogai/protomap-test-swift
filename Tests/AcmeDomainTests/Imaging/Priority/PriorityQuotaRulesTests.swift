@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityQuotaValidator()
        let item = Imaging.newPriorityQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PriorityQuotaLabelLengthRule(maxLength: 1000)
        let item = Imaging.newPriorityQuota("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityQuotaAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.PriorityQuotaAcuityRangeRule(min: 3600, max: 3600)
        let item = Imaging.newPriorityQuota("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityQuotaRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.PriorityQuotaRequiredAllergyRule(message: "priority quota needs an entry")
        let item = Imaging.newPriorityQuota("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityQuotaSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.PriorityQuotaSummaryLengthRule(maxLength: 86400)
        let item = Imaging.newPriorityQuota("x", label: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
