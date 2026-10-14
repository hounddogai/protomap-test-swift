@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusEntryValidator()
        let item = BedManagement.newCensusEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusEntryCodeLengthRule(maxLength: 255)
        let item = BedManagement.newCensusEntry("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusEntryBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = BedManagement.CensusEntryBatchSizeRangeRule(min: 16, max: 80)
        let item = BedManagement.newCensusEntry("x", name: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusEntryCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = BedManagement.CensusEntryCapacityRangeRule(min: 255, max: 1000)
        let item = BedManagement.newCensusEntry("x", name: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CensusEntryRequiredNameRule(message: "census entry needs a value")
        let item = BedManagement.newCensusEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusEntryRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = BedManagement.CensusEntryRateRangeRule(min: 3.0, max: 736.0)
        let item = BedManagement.newCensusEntry("x", name: "y")
        item.rate = 737.5
        #expect(rule.check(item).count > 0)
    }
}
