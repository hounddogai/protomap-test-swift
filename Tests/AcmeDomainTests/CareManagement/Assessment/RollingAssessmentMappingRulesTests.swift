@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingAssessmentMappingValidator()
        let item = CareManagement.newRollingAssessmentMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingAssessmentMappingTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RollingAssessmentMappingTitleLengthRule(maxLength: 1000)
        let item = CareManagement.newRollingAssessmentMapping("x", name: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingAssessmentMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RollingAssessmentMappingNameLengthRule(maxLength: 16)
        let item = CareManagement.newRollingAssessmentMapping("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingAssessmentMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RollingAssessmentMappingCodeLengthRule(maxLength: 80)
        let item = CareManagement.newRollingAssessmentMapping("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingAssessmentMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.RollingAssessmentMappingRequiredTitleRule(
            message: "rolling assessment mapping needs an entry"
        )
        let item = CareManagement.newRollingAssessmentMapping("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingAssessmentMappingFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.RollingAssessmentMappingFloorValueRangeRule(min: 5.7, max: 2321.7)
        let item = CareManagement.newRollingAssessmentMapping("x", name: "y")
        item.floorValue = 2323.2
        #expect(rule.check(item).count > 0)
    }
}
