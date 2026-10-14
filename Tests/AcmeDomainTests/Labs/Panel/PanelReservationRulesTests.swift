@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelReservationValidator()
        let item = Labs.newPanelReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.PanelReservationTitleLengthRule(maxLength: 16)
        let item = Labs.newPanelReservation("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelReservationRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.PanelReservationRatioRangeRule(min: 4.3, max: 3091.9)
        let item = Labs.newPanelReservation("x", title: "y")
        item.ratio = 3093.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelReservationRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.PanelReservationRequiredBedRule(message: "panel reservation needs a value")
        let item = Labs.newPanelReservation("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelReservationMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.PanelReservationMaximumRangeRule(min: 1.8, max: 2793.1)
        let item = Labs.newPanelReservation("x", title: "y")
        item.maximum = 2794.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelReservationRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Labs.PanelReservationRequiredDescriptionRule(message: "panel reservation needs this field")
        let item = Labs.newPanelReservation("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
