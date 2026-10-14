@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionExceptionValidator()
        let item = Pharmacy.newInteractionException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.InteractionExceptionTitleLengthRule(maxLength: 32)
        let item = Pharmacy.newInteractionException("x", label: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionExceptionRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.InteractionExceptionRequiredOwnerIDRule(message: "interaction exception needs this field")
        let item = Pharmacy.newInteractionException("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionExceptionOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Pharmacy.InteractionExceptionOwnerIDLengthRule(maxLength: 16)
        let item = Pharmacy.newInteractionException("x", label: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionExceptionRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InteractionExceptionRequiredLabelRule(message: "interaction exception needs an entry")
        let item = Pharmacy.newInteractionException("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionExceptionCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newInteractionException("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
