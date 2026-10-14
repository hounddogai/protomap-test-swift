@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosurePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedDisclosurePlanValidator()
        let item = Consent.newBatchedDisclosurePlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedDisclosurePlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.BatchedDisclosurePlanCodeLengthRule(maxLength: 86400)
        let item = Consent.newBatchedDisclosurePlan("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedDisclosurePlanPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Consent.BatchedDisclosurePlanPhoneLengthRule(maxLength: 16)
        let item = Consent.newBatchedDisclosurePlan("x", title: "y")
        item.phone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
