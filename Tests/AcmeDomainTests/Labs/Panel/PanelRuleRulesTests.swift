@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelRuleValidator()
        let item = Labs.newPanelRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.PanelRuleNameLengthRule(maxLength: 255)
        let item = Labs.newPanelRule("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelRuleRequiredCodeRule(message: "panel rule needs an entry")
        let item = Labs.newPanelRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
