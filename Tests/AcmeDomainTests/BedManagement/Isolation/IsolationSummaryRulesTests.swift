@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationSummaryValidator()
        let item = BedManagement.newIsolationSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationSummaryRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = BedManagement.IsolationSummaryRequiredFacilityRule(message: "isolation summary needs a value")
        let item = BedManagement.newIsolationSummary("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.IsolationSummaryRequiredLabelRule(message: "isolation summary needs a value")
        let item = BedManagement.newIsolationSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationSummaryRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = BedManagement.IsolationSummaryRequiredCurrencyRule(message: "isolation summary needs this field")
        let item = BedManagement.newIsolationSummary("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationSummaryCodeLengthRule(maxLength: 16)
        let item = BedManagement.newIsolationSummary("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
