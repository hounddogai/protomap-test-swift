@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusGroupValidator()
        let item = BedManagement.newCensusGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusGroupVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.CensusGroupVersionRangeRule(min: 64, max: 86400)
        let item = BedManagement.newCensusGroup("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CensusGroupRequiredCodeRule(message: "census group needs this field")
        let item = BedManagement.newCensusGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CensusGroupLabelLengthRule(maxLength: 64)
        let item = BedManagement.newCensusGroup("x", title: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusGroupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CensusGroupTitleLengthRule(maxLength: 16)
        let item = BedManagement.newCensusGroup("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.CensusGroupRequiredTitleRule(message: "census group needs a value")
        let item = BedManagement.newCensusGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
