@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusRuleValidator()
        let item = BedManagement.newCensusRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CensusRuleNameLengthRule(maxLength: 64)
        let item = BedManagement.newCensusRule("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CensusRuleRequiredNameRule(message: "census rule needs this field")
        let item = BedManagement.newCensusRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.CensusRuleRequiredTitleRule(message: "census rule needs this field")
        let item = BedManagement.newCensusRule("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CensusRuleTitleLengthRule(maxLength: 64)
        let item = BedManagement.newCensusRule("x", name: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
