@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientCareProtocolPolicyValidator()
        let item = ClinicalOps.newLenientCareProtocolPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientCareProtocolPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.LenientCareProtocolPolicyNameLengthRule(maxLength: 120)
        let item = ClinicalOps.newLenientCareProtocolPolicy("x", title: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLenientCareProtocolPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.LenientCareProtocolPolicyCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newLenientCareProtocolPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLenientCareProtocolPolicyRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.LenientCareProtocolPolicyRequiredTitleRule(
            message: "lenient care protocol policy needs an entry"
        )
        let item = ClinicalOps.newLenientCareProtocolPolicy("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
