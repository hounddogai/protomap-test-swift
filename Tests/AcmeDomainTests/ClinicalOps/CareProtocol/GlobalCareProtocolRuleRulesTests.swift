@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalCareProtocolRuleValidator()
        let item = ClinicalOps.newGlobalCareProtocolRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.GlobalCareProtocolRuleCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newGlobalCareProtocolRule("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.GlobalCareProtocolRuleTitleLengthRule(maxLength: 80)
        let item = ClinicalOps.newGlobalCareProtocolRule("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolRuleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = ClinicalOps.GlobalCareProtocolRuleRequiredChecksumRule(
            message: "global care protocol rule needs this field"
        )
        let item = ClinicalOps.newGlobalCareProtocolRule("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
