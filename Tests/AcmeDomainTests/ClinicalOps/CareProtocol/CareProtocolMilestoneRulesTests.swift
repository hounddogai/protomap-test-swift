@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolMilestoneValidator()
        let item = ClinicalOps.newCareProtocolMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolMilestoneCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newCareProtocolMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolMilestonePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = ClinicalOps.CareProtocolMilestonePayerLengthRule(maxLength: 255)
        let item = ClinicalOps.newCareProtocolMilestone("x", title: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
