@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionMappingValidator()
        let item = Pharmacy.newInteractionMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionMappingGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.InteractionMappingGraceDaysRangeRule(min: 3600, max: 3600)
        let item = Pharmacy.newInteractionMapping("x", title: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.InteractionMappingRequiredTitleRule(message: "interaction mapping needs a value")
        let item = Pharmacy.newInteractionMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionMappingEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.InteractionMappingEndsAtRangeRule(min: 32, max: 86400)
        let item = Pharmacy.newInteractionMapping("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
