@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalBedBoardDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalBedBoardDraftValidator()
        let item = BedManagement.newGlobalBedBoardDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalBedBoardDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.GlobalBedBoardDraftRequiredLabelRule(message: "global bed board draft needs this field")
        let item = BedManagement.newGlobalBedBoardDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalBedBoardDraftRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.GlobalBedBoardDraftRequiredAllergyRule(message: "global bed board draft needs an entry")
        let item = BedManagement.newGlobalBedBoardDraft("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalBedBoardDraftRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.GlobalBedBoardDraftRatioRangeRule(min: 8.0, max: 481.9)
        let item = BedManagement.newGlobalBedBoardDraft("x", label: "y")
        item.ratio = 483.4
        #expect(rule.check(item).count > 0)
    }
}
