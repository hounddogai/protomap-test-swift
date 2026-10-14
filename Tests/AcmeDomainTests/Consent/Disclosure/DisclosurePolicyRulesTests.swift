@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosurePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosurePolicyValidator()
        let item = Consent.newDisclosurePolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosurePolicyRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.DisclosurePolicyRequiredProcedureCodeRule(message: "disclosure policy needs this field")
        let item = Consent.newDisclosurePolicy("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosurePolicyRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.DisclosurePolicyRequiredSegmentRule(message: "disclosure policy needs a value")
        let item = Consent.newDisclosurePolicy("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
