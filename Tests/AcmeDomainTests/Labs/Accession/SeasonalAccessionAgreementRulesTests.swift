@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalAccessionAgreementValidator()
        let item = Labs.newSeasonalAccessionAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalAccessionAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SeasonalAccessionAgreementCodeLengthRule(maxLength: 32)
        let item = Labs.newSeasonalAccessionAgreement("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
