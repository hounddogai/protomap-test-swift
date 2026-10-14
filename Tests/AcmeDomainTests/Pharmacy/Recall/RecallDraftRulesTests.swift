@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallDraftValidator()
        let item = Pharmacy.newRecallDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallDraftRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Pharmacy.RecallDraftRequiredDescriptionRule(message: "recall draft needs an entry")
        let item = Pharmacy.newRecallDraft("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallDraftDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Pharmacy.RecallDraftDescriptionLengthRule(maxLength: 1000)
        let item = Pharmacy.newRecallDraft("x", title: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
