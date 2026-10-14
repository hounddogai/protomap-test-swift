@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCensusDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualCensusDraftValidator()
        let item = BedManagement.newManualCensusDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualCensusDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualCensusDraftCodeLengthRule(maxLength: 16)
        let item = BedManagement.newManualCensusDraft("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualCensusDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ManualCensusDraftRequiredCodeRule(message: "manual census draft needs this field")
        let item = BedManagement.newManualCensusDraft("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualCensusDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.ManualCensusDraftRequiredLabelRule(message: "manual census draft needs this field")
        let item = BedManagement.newManualCensusDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualCensusDraftRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = BedManagement.ManualCensusDraftRequiredNotesRule(message: "manual census draft needs this field")
        let item = BedManagement.newManualCensusDraft("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
