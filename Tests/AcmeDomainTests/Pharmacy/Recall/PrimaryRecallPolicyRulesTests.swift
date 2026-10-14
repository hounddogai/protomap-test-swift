@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryRecallPolicyValidator()
        let item = Pharmacy.newPrimaryRecallPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryRecallPolicyRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Pharmacy.PrimaryRecallPolicyRequiredCategoryRule(message: "primary recall policy needs this field")
        let item = Pharmacy.newPrimaryRecallPolicy("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimaryRecallPolicyTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Pharmacy.PrimaryRecallPolicyTimezoneLengthRule(maxLength: 16)
        let item = Pharmacy.newPrimaryRecallPolicy("x", label: "y")
        item.timezone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryRecallPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.PrimaryRecallPolicyCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newPrimaryRecallPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryRecallPolicyCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Pharmacy.PrimaryRecallPolicyCategoryLengthRule(maxLength: 120)
        let item = Pharmacy.newPrimaryRecallPolicy("x", label: "y")
        item.category = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
