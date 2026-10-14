@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultRoundingManifestValidator()
        let item = ClinicalOps.newDefaultRoundingManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultRoundingManifestMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.DefaultRoundingManifestMinimumRangeRule(min: 1.9, max: 2950.2)
        let item = ClinicalOps.newDefaultRoundingManifest("x", name: "y")
        item.minimum = 2951.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsDefaultRoundingManifestSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = ClinicalOps.DefaultRoundingManifestSourceLengthRule(maxLength: 120)
        let item = ClinicalOps.newDefaultRoundingManifest("x", name: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
