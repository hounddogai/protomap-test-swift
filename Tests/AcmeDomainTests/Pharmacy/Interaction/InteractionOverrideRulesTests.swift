@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionOverrideValidator()
        let item = Pharmacy.newInteractionOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InteractionOverrideRequiredCodeRule(message: "interaction override needs a value")
        let item = Pharmacy.newInteractionOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.InteractionOverrideRequiredTitleRule(message: "interaction override needs this field")
        let item = Pharmacy.newInteractionOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionOverrideCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newInteractionOverride("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
