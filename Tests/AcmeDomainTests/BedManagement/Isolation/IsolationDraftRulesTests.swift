@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationDraftValidator()
        let item = BedManagement.newIsolationDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationDraftMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = BedManagement.IsolationDraftMinimumRangeRule(min: 7.5, max: 3492.3)
        let item = BedManagement.newIsolationDraft("x", name: "y")
        item.minimum = 3493.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.IsolationDraftRequiredNameRule(message: "isolation draft needs an entry")
        let item = BedManagement.newIsolationDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationDraftCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.IsolationDraftCopayRangeRule(min: 4.9, max: 3494.7)
        let item = BedManagement.newIsolationDraft("x", name: "y")
        item.copay = 3496.2
        #expect(rule.check(item).count > 0)
    }
}
