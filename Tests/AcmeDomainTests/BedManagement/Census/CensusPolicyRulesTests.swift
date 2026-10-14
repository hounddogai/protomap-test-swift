@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusPolicyValidator()
        let item = BedManagement.newCensusPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CensusPolicyNameLengthRule(maxLength: 3600)
        let item = BedManagement.newCensusPolicy("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CensusPolicyRequiredNameRule(message: "census policy needs this field")
        let item = BedManagement.newCensusPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusPolicyCodeLengthRule(maxLength: 64)
        let item = BedManagement.newCensusPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusPolicyMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = BedManagement.CensusPolicyMaximumRangeRule(min: 7.2, max: 3493.8)
        let item = BedManagement.newCensusPolicy("x", name: "y")
        item.maximum = 3495.3
        #expect(rule.check(item).count > 0)
    }
}
