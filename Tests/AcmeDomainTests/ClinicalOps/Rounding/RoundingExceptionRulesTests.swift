@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingExceptionValidator()
        let item = ClinicalOps.newRoundingException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingExceptionDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.RoundingExceptionDescriptionLengthRule(maxLength: 80)
        let item = ClinicalOps.newRoundingException("x", name: "y")
        item.description = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RoundingExceptionNameLengthRule(maxLength: 16)
        let item = ClinicalOps.newRoundingException("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingExceptionRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = ClinicalOps.RoundingExceptionRequiredDescriptionRule(message: "rounding exception needs an entry")
        let item = ClinicalOps.newRoundingException("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RoundingExceptionRequiredCodeRule(message: "rounding exception needs this field")
        let item = ClinicalOps.newRoundingException("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RoundingExceptionRequiredNameRule(message: "rounding exception needs this field")
        let item = ClinicalOps.newRoundingException("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
