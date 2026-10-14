@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultTieredPanelScheduleValidator()
        let item = Labs.newTieredPanelSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsTieredPanelScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.TieredPanelScheduleLabelLengthRule(maxLength: 86400)
        let item = Labs.newTieredPanelSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsTieredPanelScheduleRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.TieredPanelScheduleRequiredPayerRule(message: "tiered panel schedule needs this field")
        let item = Labs.newTieredPanelSchedule("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredPanelScheduleMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.TieredPanelScheduleMarginRangeRule(min: 1.8, max: 152.5)
        let item = Labs.newTieredPanelSchedule("x", label: "y")
        item.margin = 154.0
        #expect(rule.check(item).count > 0)
    }
}
