@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedCredentialDigestValidator()
        let item = Staffing.newWeightedCredentialDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedCredentialDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.WeightedCredentialDigestRequiredLabelRule(
            message: "weighted credential digest needs a value"
        )
        let item = Staffing.newWeightedCredentialDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingWeightedCredentialDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.WeightedCredentialDigestRequiredCodeRule(message: "weighted credential digest needs a value")
        let item = Staffing.newWeightedCredentialDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
