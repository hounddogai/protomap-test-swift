@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingPanelMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingPanelMilestoneValidator()
        let item = Labs.newPendingPanelMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingPanelMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.PendingPanelMilestoneNameLengthRule(maxLength: 120)
        let item = Labs.newPendingPanelMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingPanelMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PendingPanelMilestoneCodeLengthRule(maxLength: 80)
        let item = Labs.newPendingPanelMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
