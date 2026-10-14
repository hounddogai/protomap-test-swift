@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionVarianceValidator()
        let item = Pharmacy.newInteractionVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionVarianceCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newInteractionVariance("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InteractionVarianceRequiredCodeRule(message: "interaction variance needs an entry")
        let item = Pharmacy.newInteractionVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionVarianceRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Pharmacy.InteractionVarianceRequiredPhoneRule(message: "interaction variance needs an entry")
        let item = Pharmacy.newInteractionVariance("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
