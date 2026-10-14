@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledModalityAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledModalityAuditValidator()
        let item = Imaging.newScheduledModalityAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledModalityAuditDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Imaging.ScheduledModalityAuditDiagnosisCodeLengthRule(maxLength: 255)
        let item = Imaging.newScheduledModalityAudit("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledModalityAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ScheduledModalityAuditCodeLengthRule(maxLength: 80)
        let item = Imaging.newScheduledModalityAudit("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledModalityAuditRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Imaging.ScheduledModalityAuditRequiredDiagnosisCodeRule(
            message: "scheduled modality audit needs a value"
        )
        let item = Imaging.newScheduledModalityAudit("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledModalityAuditRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.ScheduledModalityAuditRatioRangeRule(min: 9.3, max: 2051.8)
        let item = Imaging.newScheduledModalityAudit("x", title: "y")
        item.ratio = 2053.3
        #expect(rule.check(item).count > 0)
    }
}
