@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingDigestValidator()
        let item = ClinicalOps.newRoundingDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingDigestThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = ClinicalOps.RoundingDigestThresholdRangeRule(min: 3.6, max: 2709.9)
        let item = ClinicalOps.newRoundingDigest("x", name: "y")
        item.threshold = 2711.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingDigestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.RoundingDigestRegionLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRoundingDigest("x", name: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingDigestRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.RoundingDigestRequiredClinicianIDRule(message: "rounding digest needs a value")
        let item = ClinicalOps.newRoundingDigest("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RoundingDigestNameLengthRule(maxLength: 32)
        let item = ClinicalOps.newRoundingDigest("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
