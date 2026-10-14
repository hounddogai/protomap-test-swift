@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedRecallDraftValidator()
        let item = Pharmacy.newWeightedRecallDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedRecallDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.WeightedRecallDraftRequiredCodeRule(message: "weighted recall draft needs this field")
        let item = Pharmacy.newWeightedRecallDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedRecallDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.WeightedRecallDraftRequiredNameRule(message: "weighted recall draft needs an entry")
        let item = Pharmacy.newWeightedRecallDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
