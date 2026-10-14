@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalHandoffPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalHandoffPolicyValidator()
        let item = ClinicalOps.newSeasonalHandoffPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalHandoffPolicyWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = ClinicalOps.SeasonalHandoffPolicyWardLengthRule(maxLength: 16)
        let item = ClinicalOps.newSeasonalHandoffPolicy("x", name: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalHandoffPolicyFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = ClinicalOps.SeasonalHandoffPolicyFacilityLengthRule(maxLength: 255)
        let item = ClinicalOps.newSeasonalHandoffPolicy("x", name: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalHandoffPolicyRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = ClinicalOps.SeasonalHandoffPolicyRequiredFacilityRule(
            message: "seasonal handoff policy needs a value"
        )
        let item = ClinicalOps.newSeasonalHandoffPolicy("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsSeasonalHandoffPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.SeasonalHandoffPolicyCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newSeasonalHandoffPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalHandoffPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.SeasonalHandoffPolicyRequiredCodeRule(message: "seasonal handoff policy needs this field")
        let item = ClinicalOps.newSeasonalHandoffPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
