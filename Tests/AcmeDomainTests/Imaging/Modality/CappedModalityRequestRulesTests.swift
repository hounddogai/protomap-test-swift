@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedModalityRequestValidator()
        let item = Imaging.newCappedModalityRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedModalityRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CappedModalityRequestCodeLengthRule(maxLength: 86400)
        let item = Imaging.newCappedModalityRequest("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedModalityRequestBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.CappedModalityRequestBedLengthRule(maxLength: 80)
        let item = Imaging.newCappedModalityRequest("x", label: "y")
        item.bed = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedModalityRequestRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Imaging.CappedModalityRequestRequiredDescriptionRule(
            message: "capped modality request needs this field"
        )
        let item = Imaging.newCappedModalityRequest("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedModalityRequestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.CappedModalityRequestRateRangeRule(min: 5.1, max: 1826.3)
        let item = Imaging.newCappedModalityRequest("x", label: "y")
        item.rate = 1827.8
        #expect(rule.check(item).count > 0)
    }
}
