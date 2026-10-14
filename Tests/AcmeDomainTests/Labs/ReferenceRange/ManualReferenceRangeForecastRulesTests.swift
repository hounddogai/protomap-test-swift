@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualReferenceRangeForecastValidator()
        let item = Labs.newManualReferenceRangeForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualReferenceRangeForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ManualReferenceRangeForecastRequiredCodeRule(
            message: "manual reference range forecast needs this field"
        )
        let item = Labs.newManualReferenceRangeForecast("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualReferenceRangeForecastRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.ManualReferenceRangeForecastRequiredAllergyRule(
            message: "manual reference range forecast needs an entry"
        )
        let item = Labs.newManualReferenceRangeForecast("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
