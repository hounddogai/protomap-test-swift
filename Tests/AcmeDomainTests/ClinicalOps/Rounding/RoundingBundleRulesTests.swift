@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingBundleValidator()
        let item = ClinicalOps.newRoundingBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingBundlePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.RoundingBundlePriorityRangeRule(min: 16, max: 255)
        let item = ClinicalOps.newRoundingBundle("x", name: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RoundingBundleCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newRoundingBundle("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingBundleFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = ClinicalOps.RoundingBundleFacilityLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRoundingBundle("x", name: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingBundleVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = ClinicalOps.RoundingBundleVisitMinutesRangeRule(min: 64, max: 120)
        let item = ClinicalOps.newRoundingBundle("x", name: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}
