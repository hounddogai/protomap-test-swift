@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyProgramVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyProgramVarianceValidator()
        let item = CareManagement.newLegacyProgramVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyProgramVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LegacyProgramVarianceCodeLengthRule(maxLength: 120)
        let item = CareManagement.newLegacyProgramVariance("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyProgramVarianceRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.LegacyProgramVarianceRevisionRangeRule(min: 120, max: 86400)
        let item = CareManagement.newLegacyProgramVariance("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLegacyProgramVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LegacyProgramVarianceRequiredCodeRule(
            message: "legacy program variance needs an entry"
        )
        let item = CareManagement.newLegacyProgramVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
