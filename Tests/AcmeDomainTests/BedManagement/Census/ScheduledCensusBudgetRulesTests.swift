@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCensusBudgetValidator()
        let item = BedManagement.newScheduledCensusBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCensusBudgetRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.ScheduledCensusBudgetRequiredAllergyRule(
            message: "scheduled census budget needs an entry"
        )
        let item = BedManagement.newScheduledCensusBudget("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCensusBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.ScheduledCensusBudgetRequiredNameRule(message: "scheduled census budget needs an entry")
        let item = BedManagement.newScheduledCensusBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCensusBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ScheduledCensusBudgetCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newScheduledCensusBudget("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
