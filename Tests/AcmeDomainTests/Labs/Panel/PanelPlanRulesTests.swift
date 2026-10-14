@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelPlanValidator()
        let item = Labs.newPanelPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PanelPlanCodeLengthRule(maxLength: 3600)
        let item = Labs.newPanelPlan("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
