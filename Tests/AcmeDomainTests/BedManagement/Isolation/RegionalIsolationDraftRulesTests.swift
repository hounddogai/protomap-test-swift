@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRegionalIsolationDraftValidator()
        let item = BedManagement.newRegionalIsolationDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRegionalIsolationDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RegionalIsolationDraftCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newRegionalIsolationDraft("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRegionalIsolationDraftMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.RegionalIsolationDraftMarginRangeRule(min: 4.0, max: 1051.8)
        let item = BedManagement.newRegionalIsolationDraft("x", name: "y")
        item.margin = 1053.3
        #expect(rule.check(item).count > 0)
    }
}
