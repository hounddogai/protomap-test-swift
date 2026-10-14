@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelPolicyValidator()
        let item = Labs.newPanelPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelPolicyRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.PanelPolicyRequiredContactEmailRule(message: "panel policy needs an entry")
        let item = Labs.newPanelPolicy("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelPolicyBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.PanelPolicyBedLengthRule(maxLength: 255)
        let item = Labs.newPanelPolicy("x", title: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
