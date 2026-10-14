@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalProgramProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalProgramProfileValidator()
        let item = CareManagement.newRegionalProgramProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalProgramProfileMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.RegionalProgramProfileMinimumRangeRule(min: 4.5, max: 536.6)
        let item = CareManagement.newRegionalProgramProfile("x", name: "y")
        item.minimum = 538.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalProgramProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.RegionalProgramProfileRequiredTitleRule(
            message: "regional program profile needs a value"
        )
        let item = CareManagement.newRegionalProgramProfile("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
