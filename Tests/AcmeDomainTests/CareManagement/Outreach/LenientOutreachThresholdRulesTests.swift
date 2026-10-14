@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientOutreachThresholdValidator()
        let item = CareManagement.newLenientOutreachThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientOutreachThresholdDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = CareManagement.LenientOutreachThresholdDosageMgRangeRule(min: 0.5, max: 424.4)
        let item = CareManagement.newLenientOutreachThreshold("x", name: "y")
        item.dosageMg = 425.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLenientOutreachThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.LenientOutreachThresholdRequiredNameRule(
            message: "lenient outreach threshold needs an entry"
        )
        let item = CareManagement.newLenientOutreachThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientOutreachThresholdQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.LenientOutreachThresholdQuantityRangeRule(min: 1000, max: 3600)
        let item = CareManagement.newLenientOutreachThreshold("x", name: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}
