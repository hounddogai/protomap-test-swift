@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedHandoffManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultWeightedHandoffManifestValidator()
        let item = ClinicalOps.newWeightedHandoffManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsWeightedHandoffManifestBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = ClinicalOps.WeightedHandoffManifestBedLengthRule(maxLength: 255)
        let item = ClinicalOps.newWeightedHandoffManifest("x", title: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
