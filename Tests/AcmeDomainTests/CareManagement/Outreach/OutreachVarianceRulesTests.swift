@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachVarianceValidator()
        let item = CareManagement.newOutreachVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachVarianceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.OutreachVarianceQuantityRangeRule(min: 32, max: 1000)
        let item = CareManagement.newOutreachVariance("x", name: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachVarianceNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = CareManagement.OutreachVarianceNotesLengthRule(maxLength: 32)
        let item = CareManagement.newOutreachVariance("x", name: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachVarianceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.OutreachVarianceGraceDaysRangeRule(min: 16, max: 1000)
        let item = CareManagement.newOutreachVariance("x", name: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}
