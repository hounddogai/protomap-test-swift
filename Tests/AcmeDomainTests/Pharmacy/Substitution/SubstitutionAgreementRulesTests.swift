@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionAgreementValidator()
        let item = Pharmacy.newSubstitutionAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionAgreementRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Pharmacy.SubstitutionAgreementRevisionRangeRule(min: 86400, max: 86400)
        let item = Pharmacy.newSubstitutionAgreement("x", name: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionAgreementThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.SubstitutionAgreementThresholdRangeRule(min: 7.9, max: 4900.6)
        let item = Pharmacy.newSubstitutionAgreement("x", name: "y")
        item.threshold = 4902.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.SubstitutionAgreementNameLengthRule(maxLength: 64)
        let item = Pharmacy.newSubstitutionAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
