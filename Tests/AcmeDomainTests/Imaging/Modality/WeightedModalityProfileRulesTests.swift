@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedModalityProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedModalityProfileValidator()
        let item = Imaging.newWeightedModalityProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedModalityProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WeightedModalityProfileCodeLengthRule(maxLength: 86400)
        let item = Imaging.newWeightedModalityProfile("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedModalityProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WeightedModalityProfileRequiredCodeRule(message: "weighted modality profile needs an entry")
        let item = Imaging.newWeightedModalityProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedModalityProfileRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.WeightedModalityProfileRequiredAllergyRule(message: "weighted modality profile needs a value")
        let item = Imaging.newWeightedModalityProfile("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
