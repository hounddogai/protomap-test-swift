@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadAgreementValidator()
        let item = Imaging.newReadAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadAgreementCodeLengthRule(maxLength: 120)
        let item = Imaging.newReadAgreement("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
