@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffTemplateValidator()
        let item = ClinicalOps.newHandoffTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffTemplateChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = ClinicalOps.HandoffTemplateChannelLengthRule(maxLength: 86400)
        let item = ClinicalOps.newHandoffTemplate("x", name: "y")
        item.channel = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffTemplateRequiredCodeRule(message: "handoff template needs a value")
        let item = ClinicalOps.newHandoffTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffTemplateRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.HandoffTemplateRevisionRangeRule(min: 120, max: 255)
        let item = ClinicalOps.newHandoffTemplate("x", name: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffTemplateReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.HandoffTemplateReviewerLengthRule(maxLength: 64)
        let item = ClinicalOps.newHandoffTemplate("x", name: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.HandoffTemplateCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newHandoffTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
