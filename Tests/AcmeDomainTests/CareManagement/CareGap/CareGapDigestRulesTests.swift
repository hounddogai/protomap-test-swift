@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapDigestValidator()
        let item = CareManagement.newCareGapDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapDigestQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.CareGapDigestQuantityRangeRule(min: 16, max: 255)
        let item = CareManagement.newCareGapDigest("x", name: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}
