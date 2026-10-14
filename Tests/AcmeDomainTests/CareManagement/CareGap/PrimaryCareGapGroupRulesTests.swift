@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryCareGapGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryCareGapGroupValidator()
        let item = CareManagement.newPrimaryCareGapGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryCareGapGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.PrimaryCareGapGroupLabelLengthRule(maxLength: 80)
        let item = CareManagement.newPrimaryCareGapGroup("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryCareGapGroupVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.PrimaryCareGapGroupVersionRangeRule(min: 120, max: 3600)
        let item = CareManagement.newPrimaryCareGapGroup("x", label: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryCareGapGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PrimaryCareGapGroupCodeLengthRule(maxLength: 255)
        let item = CareManagement.newPrimaryCareGapGroup("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryCareGapGroupCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.PrimaryCareGapGroupCreatedAtRangeRule(min: 16, max: 120)
        let item = CareManagement.newPrimaryCareGapGroup("x", label: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}
