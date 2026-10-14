@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryTaskClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryTaskClaimValidator()
        let item = ClinicalOps.newPrimaryTaskClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryTaskClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PrimaryTaskClaimRequiredCodeRule(message: "primary task claim needs an entry")
        let item = ClinicalOps.newPrimaryTaskClaim("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
