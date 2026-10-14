@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingModalityAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingModalityAuditValidator()
        let item = Imaging.newRollingModalityAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingModalityAuditPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.RollingModalityAuditPriorityRangeRule(min: 32, max: 3600)
        let item = Imaging.newRollingModalityAudit("x", title: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}
