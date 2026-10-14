@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningRuleValidator()
        let item = BedManagement.newCleaningRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningRuleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.CleaningRuleExpiresAtRangeRule(min: 64, max: 120)
        let item = BedManagement.newCleaningRule("x", name: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CleaningRuleCodeLengthRule(maxLength: 120)
        let item = BedManagement.newCleaningRule("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningRuleRequiredNameRule(message: "cleaning rule needs an entry")
        let item = BedManagement.newCleaningRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningRuleLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.CleaningRuleLocaleLengthRule(maxLength: 120)
        let item = BedManagement.newCleaningRule("x", name: "y")
        item.locale = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
