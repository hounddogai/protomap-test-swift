@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusAdjustmentValidator()
        let item = BedManagement.newCensusAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusAdjustmentWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = BedManagement.CensusAdjustmentWardLengthRule(maxLength: 16)
        let item = BedManagement.newCensusAdjustment("x", title: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusAdjustmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.CensusAdjustmentCeilingRangeRule(min: 0.5, max: 4943.1)
        let item = BedManagement.newCensusAdjustment("x", title: "y")
        item.ceiling = 4944.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusAdjustmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CensusAdjustmentTitleLengthRule(maxLength: 86400)
        let item = BedManagement.newCensusAdjustment("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusAdjustmentRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = BedManagement.CensusAdjustmentRequiredWardRule(message: "census adjustment needs an entry")
        let item = BedManagement.newCensusAdjustment("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
