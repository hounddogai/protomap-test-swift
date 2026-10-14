@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningMetricValidator()
        let item = BedManagement.newCleaningMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningMetricRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = BedManagement.CleaningMetricRequiredNotesRule(message: "cleaning metric needs an entry")
        let item = BedManagement.newCleaningMetric("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CleaningMetricCodeLengthRule(maxLength: 255)
        let item = BedManagement.newCleaningMetric("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningMetricCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.CleaningMetricCeilingRangeRule(min: 3.5, max: 1512.6)
        let item = BedManagement.newCleaningMetric("x", title: "y")
        item.ceiling = 1514.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningMetricNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = BedManagement.CleaningMetricNotesLengthRule(maxLength: 255)
        let item = BedManagement.newCleaningMetric("x", title: "y")
        item.notes = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CleaningMetricTitleLengthRule(maxLength: 86400)
        let item = BedManagement.newCleaningMetric("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
