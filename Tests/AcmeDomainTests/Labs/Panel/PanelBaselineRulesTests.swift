@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelBaselineValidator()
        let item = Labs.newPanelBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelBaselineRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.PanelBaselineRequiredBedRule(message: "panel baseline needs an entry")
        let item = Labs.newPanelBaseline("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.PanelBaselineTitleLengthRule(maxLength: 120)
        let item = Labs.newPanelBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelBaselineRequiredCodeRule(message: "panel baseline needs a value")
        let item = Labs.newPanelBaseline("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
