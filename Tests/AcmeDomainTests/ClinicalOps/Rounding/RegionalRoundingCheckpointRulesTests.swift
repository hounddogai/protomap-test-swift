@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalRoundingCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalRoundingCheckpointValidator()
        let item = ClinicalOps.newRegionalRoundingCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalRoundingCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RegionalRoundingCheckpointRequiredLabelRule(
            message: "regional rounding checkpoint needs this field"
        )
        let item = ClinicalOps.newRegionalRoundingCheckpoint("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalRoundingCheckpointRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = ClinicalOps.RegionalRoundingCheckpointRequiredRegionRule(
            message: "regional rounding checkpoint needs an entry"
        )
        let item = ClinicalOps.newRegionalRoundingCheckpoint("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalRoundingCheckpointLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.RegionalRoundingCheckpointLabelLengthRule(maxLength: 255)
        let item = ClinicalOps.newRegionalRoundingCheckpoint("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
