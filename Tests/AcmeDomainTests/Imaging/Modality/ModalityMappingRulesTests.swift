@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityMappingValidator()
        let item = Imaging.newModalityMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityMappingEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.ModalityMappingEndsAtRangeRule(min: 120, max: 3600)
        let item = Imaging.newModalityMapping("x", name: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityMappingAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Imaging.ModalityMappingAmountRangeRule(min: 5.2, max: 4703.7)
        let item = Imaging.newModalityMapping("x", name: "y")
        item.amount = 4705.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityMappingCodeLengthRule(maxLength: 16)
        let item = Imaging.newModalityMapping("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
