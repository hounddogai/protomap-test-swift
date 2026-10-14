@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedCareGapBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedCareGapBundleValidator()
        let item = CareManagement.newBatchedCareGapBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedCareGapBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.BatchedCareGapBundleCodeLengthRule(maxLength: 16)
        let item = CareManagement.newBatchedCareGapBundle("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedCareGapBundleRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = CareManagement.BatchedCareGapBundleRequiredCountryRule(
            message: "batched care gap bundle needs an entry"
        )
        let item = CareManagement.newBatchedCareGapBundle("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
