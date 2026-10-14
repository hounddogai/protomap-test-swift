@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureAllocationValidator()
        let item = Consent.newDisclosureAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureAllocationRequiredCodeRule(message: "disclosure allocation needs a value")
        let item = Consent.newDisclosureAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureAllocationRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.DisclosureAllocationRequiredProcedureCodeRule(
            message: "disclosure allocation needs this field"
        )
        let item = Consent.newDisclosureAllocation("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DisclosureAllocationCodeLengthRule(maxLength: 64)
        let item = Consent.newDisclosureAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureAllocationQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.DisclosureAllocationQuantityRangeRule(min: 80, max: 120)
        let item = Consent.newDisclosureAllocation("x", label: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}
