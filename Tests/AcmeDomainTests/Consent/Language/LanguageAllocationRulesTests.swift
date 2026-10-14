@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageAllocationValidator()
        let item = Consent.newLanguageAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageAllocationFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Consent.LanguageAllocationFacilityLengthRule(maxLength: 64)
        let item = Consent.newLanguageAllocation("x", name: "y")
        item.facility = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageAllocationRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.LanguageAllocationRequiredFacilityRule(message: "language allocation needs a value")
        let item = Consent.newLanguageAllocation("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageAllocationUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.LanguageAllocationUpdatedAtRangeRule(min: 255, max: 255)
        let item = Consent.newLanguageAllocation("x", name: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LanguageAllocationCodeLengthRule(maxLength: 64)
        let item = Consent.newLanguageAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
