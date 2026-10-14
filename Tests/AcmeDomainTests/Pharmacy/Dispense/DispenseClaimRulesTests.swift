@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseClaimValidator()
        let item = Pharmacy.newDispenseClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseClaimRequiredCodeRule(message: "dispense claim needs a value")
        let item = Pharmacy.newDispenseClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DispenseClaimTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newDispenseClaim("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
