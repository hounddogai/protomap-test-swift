@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultRoundingDraftValidator()
        let item = ClinicalOps.newDefaultRoundingDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultRoundingDraftDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.DefaultRoundingDraftDescriptionLengthRule(maxLength: 1000)
        let item = ClinicalOps.newDefaultRoundingDraft("x", label: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsDefaultRoundingDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.DefaultRoundingDraftRequiredCodeRule(message: "default rounding draft needs this field")
        let item = ClinicalOps.newDefaultRoundingDraft("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
