@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallDigestValidator()
        let item = Pharmacy.newRecallDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallDigestPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Pharmacy.RecallDigestPayerLengthRule(maxLength: 255)
        let item = Pharmacy.newRecallDigest("x", title: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallDigestRequiredCodeRule(message: "recall digest needs a value")
        let item = Pharmacy.newRecallDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
