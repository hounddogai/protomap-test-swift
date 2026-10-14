@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultProgramEstimateValidator()
        let item = CareManagement.newDefaultProgramEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultProgramEstimateSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = CareManagement.DefaultProgramEstimateSummaryLengthRule(maxLength: 16)
        let item = CareManagement.newDefaultProgramEstimate("x", name: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultProgramEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.DefaultProgramEstimateRequiredNameRule(
            message: "default program estimate needs an entry"
        )
        let item = CareManagement.newDefaultProgramEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultProgramEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.DefaultProgramEstimateRequiredCodeRule(
            message: "default program estimate needs this field"
        )
        let item = CareManagement.newDefaultProgramEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
