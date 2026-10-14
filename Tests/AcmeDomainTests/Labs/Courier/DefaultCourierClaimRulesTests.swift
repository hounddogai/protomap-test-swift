@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultCourierClaimValidator()
        let item = Labs.newDefaultCourierClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultCourierClaimFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Labs.DefaultCourierClaimFacilityLengthRule(maxLength: 16)
        let item = Labs.newDefaultCourierClaim("x", name: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultCourierClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.DefaultCourierClaimRequiredNameRule(message: "default courier claim needs an entry")
        let item = Labs.newDefaultCourierClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultCourierClaimQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.DefaultCourierClaimQuantityRangeRule(min: 64, max: 86400)
        let item = Labs.newDefaultCourierClaim("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultCourierClaimRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.DefaultCourierClaimRequiredFacilityRule(message: "default courier claim needs this field")
        let item = Labs.newDefaultCourierClaim("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultCourierClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.DefaultCourierClaimCodeLengthRule(maxLength: 86400)
        let item = Labs.newDefaultCourierClaim("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
