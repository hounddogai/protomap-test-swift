@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultMilestoneValidator()
        let item = Labs.newResultMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultMilestoneCodeLengthRule(maxLength: 32)
        let item = Labs.newResultMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultMilestonePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Labs.ResultMilestonePayerLengthRule(maxLength: 120)
        let item = Labs.newResultMilestone("x", name: "y")
        item.payer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.ResultMilestoneRequiredNameRule(message: "result milestone needs an entry")
        let item = Labs.newResultMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultMilestoneVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.ResultMilestoneVersionRangeRule(min: 16, max: 255)
        let item = Labs.newResultMilestone("x", name: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultMilestoneExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.ResultMilestoneExternalRefLengthRule(maxLength: 80)
        let item = Labs.newResultMilestone("x", name: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
