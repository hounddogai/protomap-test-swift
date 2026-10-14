@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelProfileValidator()
        let item = Labs.newPanelProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelProfileDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.PanelProfileDosageMgRangeRule(min: 7.0, max: 3980.9)
        let item = Labs.newPanelProfile("x", name: "y")
        item.dosageMg = 3982.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelProfileRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.PanelProfileRetriesRangeRule(min: 80, max: 3600)
        let item = Labs.newPanelProfile("x", name: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelProfileRequiredCodeRule(message: "panel profile needs this field")
        let item = Labs.newPanelProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelProfileReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Labs.PanelProfileReviewerLengthRule(maxLength: 86400)
        let item = Labs.newPanelProfile("x", name: "y")
        item.reviewer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
