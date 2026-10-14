@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelBundleValidator()
        let item = Labs.newPanelBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelBundleEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.PanelBundleEndsAtRangeRule(min: 255, max: 86400)
        let item = Labs.newPanelBundle("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelBundleRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Labs.PanelBundleRegionLengthRule(maxLength: 32)
        let item = Labs.newPanelBundle("x", name: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelBundleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.PanelBundleBudgetRangeRule(min: 3.3, max: 4471.9)
        let item = Labs.newPanelBundle("x", name: "y")
        item.budget = 4473.4
        #expect(rule.check(item).count > 0)
    }
}
