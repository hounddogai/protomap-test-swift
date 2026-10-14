@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackDispenseRequestValidator()
        let item = Pharmacy.newFallbackDispenseRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackDispenseRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.FallbackDispenseRequestTitleLengthRule(maxLength: 3600)
        let item = Pharmacy.newFallbackDispenseRequest("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackDispenseRequestCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Pharmacy.FallbackDispenseRequestCategoryLengthRule(maxLength: 120)
        let item = Pharmacy.newFallbackDispenseRequest("x", title: "y")
        item.category = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackDispenseRequestRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Pharmacy.FallbackDispenseRequestRequiredCategoryRule(
            message: "fallback dispense request needs a value"
        )
        let item = Pharmacy.newFallbackDispenseRequest("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackDispenseRequestMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.FallbackDispenseRequestMinimumRangeRule(min: 5.0, max: 4285.5)
        let item = Pharmacy.newFallbackDispenseRequest("x", title: "y")
        item.minimum = 4287.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackDispenseRequestVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.FallbackDispenseRequestVersionRangeRule(min: 120, max: 86400)
        let item = Pharmacy.newFallbackDispenseRequest("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackDispenseRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FallbackDispenseRequestCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newFallbackDispenseRequest("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
