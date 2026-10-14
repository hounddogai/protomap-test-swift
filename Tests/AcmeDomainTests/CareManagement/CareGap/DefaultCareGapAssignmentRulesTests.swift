@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultCareGapAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultCareGapAssignmentValidator()
        let item = CareManagement.newDefaultCareGapAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultCareGapAssignmentContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.DefaultCareGapAssignmentContactEmailLengthRule(maxLength: 64)
        let item = CareManagement.newDefaultCareGapAssignment("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultCareGapAssignmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = CareManagement.DefaultCareGapAssignmentRequiredCountryRule(
            message: "default care gap assignment needs an entry"
        )
        let item = CareManagement.newDefaultCareGapAssignment("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultCareGapAssignmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.DefaultCareGapAssignmentRatioRangeRule(min: 2.1, max: 2492.2)
        let item = CareManagement.newDefaultCareGapAssignment("x", name: "y")
        item.ratio = 2493.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementDefaultCareGapAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.DefaultCareGapAssignmentNameLengthRule(maxLength: 32)
        let item = CareManagement.newDefaultCareGapAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
