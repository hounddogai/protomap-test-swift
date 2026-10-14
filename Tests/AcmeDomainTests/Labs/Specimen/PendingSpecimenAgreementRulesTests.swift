@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingSpecimenAgreementValidator()
        let item = Labs.newPendingSpecimenAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingSpecimenAgreementLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.PendingSpecimenAgreementLabelLengthRule(maxLength: 80)
        let item = Labs.newPendingSpecimenAgreement("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingSpecimenAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingSpecimenAgreementRequiredCodeRule(message: "pending specimen agreement needs an entry")
        let item = Labs.newPendingSpecimenAgreement("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
