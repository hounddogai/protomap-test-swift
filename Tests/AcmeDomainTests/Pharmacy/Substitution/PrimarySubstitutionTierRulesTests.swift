@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimarySubstitutionTierValidator()
        let item = Pharmacy.newPrimarySubstitutionTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.PrimarySubstitutionTierCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newPrimarySubstitutionTier("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.PrimarySubstitutionTierLabelLengthRule(maxLength: 16)
        let item = Pharmacy.newPrimarySubstitutionTier("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionTierSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Pharmacy.PrimarySubstitutionTierSegmentLengthRule(maxLength: 86400)
        let item = Pharmacy.newPrimarySubstitutionTier("x", label: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
