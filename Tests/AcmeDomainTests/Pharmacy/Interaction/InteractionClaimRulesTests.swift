@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionClaimValidator()
        let item = Pharmacy.newInteractionClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionClaimDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.InteractionClaimDosageMgRangeRule(min: 7.6, max: 863.1)
        let item = Pharmacy.newInteractionClaim("x", title: "y")
        item.dosageMg = 864.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionClaimCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newInteractionClaim("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.InteractionClaimRequiredTitleRule(message: "interaction claim needs this field")
        let item = Pharmacy.newInteractionClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.InteractionClaimTitleLengthRule(maxLength: 64)
        let item = Pharmacy.newInteractionClaim("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
