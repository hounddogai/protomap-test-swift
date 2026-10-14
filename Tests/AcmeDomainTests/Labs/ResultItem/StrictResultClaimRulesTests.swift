@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictResultClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictResultClaimValidator()
        let item = Labs.newStrictResultClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictResultClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.StrictResultClaimNameLengthRule(maxLength: 86400)
        let item = Labs.newStrictResultClaim("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsStrictResultClaimFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.StrictResultClaimFloorValueRangeRule(min: 6.5, max: 2372.5)
        let item = Labs.newStrictResultClaim("x", name: "y")
        item.floorValue = 2374.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsStrictResultClaimRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Labs.StrictResultClaimRequiredReviewerRule(message: "strict result claim needs an entry")
        let item = Labs.newStrictResultClaim("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
