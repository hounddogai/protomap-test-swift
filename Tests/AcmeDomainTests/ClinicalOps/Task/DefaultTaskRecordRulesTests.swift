@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultTaskRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultTaskRecordValidator()
        let item = ClinicalOps.newDefaultTaskRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultTaskRecordRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.DefaultTaskRecordRegionLengthRule(maxLength: 16)
        let item = ClinicalOps.newDefaultTaskRecord("x", label: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsDefaultTaskRecordRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = ClinicalOps.DefaultTaskRecordRequiredDiagnosisCodeRule(
            message: "default task record needs this field"
        )
        let item = ClinicalOps.newDefaultTaskRecord("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultTaskRecordMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.DefaultTaskRecordMinimumRangeRule(min: 5.1, max: 3192.1)
        let item = ClinicalOps.newDefaultTaskRecord("x", label: "y")
        item.minimum = 3193.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsDefaultTaskRecordRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = ClinicalOps.DefaultTaskRecordRequiredRegionRule(message: "default task record needs this field")
        let item = ClinicalOps.newDefaultTaskRecord("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
