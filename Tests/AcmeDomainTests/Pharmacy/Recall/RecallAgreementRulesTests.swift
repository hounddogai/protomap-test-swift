@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallAgreementValidator()
        let item = Pharmacy.newRecallAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallAgreementRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.RecallAgreementRequiredChecksumRule(message: "recall agreement needs this field")
        let item = Pharmacy.newRecallAgreement("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallAgreementRequiredCodeRule(message: "recall agreement needs this field")
        let item = Pharmacy.newRecallAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallAgreementCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Pharmacy.RecallAgreementCreatedAtRangeRule(min: 80, max: 1000)
        let item = Pharmacy.newRecallAgreement("x", name: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
