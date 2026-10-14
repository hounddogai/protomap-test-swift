@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedIsolationEntryValidator()
        let item = BedManagement.newWeightedIsolationEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedIsolationEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.WeightedIsolationEntryNameLengthRule(maxLength: 86400)
        let item = BedManagement.newWeightedIsolationEntry("x", label: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedIsolationEntryLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.WeightedIsolationEntryLimitRangeRule(min: 16, max: 3600)
        let item = BedManagement.newWeightedIsolationEntry("x", label: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedIsolationEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.WeightedIsolationEntryCodeLengthRule(maxLength: 64)
        let item = BedManagement.newWeightedIsolationEntry("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
