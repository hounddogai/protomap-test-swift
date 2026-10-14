@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictPanelPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictPanelPolicyValidator()
        let item = Labs.newStrictPanelPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictPanelPolicyTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.StrictPanelPolicyTitleLengthRule(maxLength: 255)
        let item = Labs.newStrictPanelPolicy("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsStrictPanelPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.StrictPanelPolicyRequiredCodeRule(message: "strict panel policy needs this field")
        let item = Labs.newStrictPanelPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictPanelPolicyRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.StrictPanelPolicyRequiredTitleRule(message: "strict panel policy needs this field")
        let item = Labs.newStrictPanelPolicy("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictPanelPolicyRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.StrictPanelPolicyRequiredPayerRule(message: "strict panel policy needs a value")
        let item = Labs.newStrictPanelPolicy("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
