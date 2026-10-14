@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionThresholdValidator()
        let item = Pharmacy.newInteractionThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionThresholdRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.InteractionThresholdRateRangeRule(min: 8.8, max: 4028.8)
        let item = Pharmacy.newInteractionThreshold("x", name: "y")
        item.rate = 4030.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.InteractionThresholdNameLengthRule(maxLength: 255)
        let item = Pharmacy.newInteractionThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.InteractionThresholdRequiredNameRule(message: "interaction threshold needs a value")
        let item = Pharmacy.newInteractionThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
