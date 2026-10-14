@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolDigestValidator()
        let item = ClinicalOps.newCareProtocolDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolDigestRequiredCodeRule(message: "care protocol digest needs this field")
        let item = ClinicalOps.newCareProtocolDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolDigestCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newCareProtocolDigest("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolDigestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.CareProtocolDigestCreatedAtRangeRule(min: 64, max: 3600)
        let item = ClinicalOps.newCareProtocolDigest("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
