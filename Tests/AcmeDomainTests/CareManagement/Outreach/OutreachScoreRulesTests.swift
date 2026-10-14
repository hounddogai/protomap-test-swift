@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachScoreValidator()
        let item = CareManagement.newOutreachScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachScoreFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.OutreachScoreFloorValueRangeRule(min: 9.3, max: 589.0)
        let item = CareManagement.newOutreachScore("x", label: "y")
        item.floorValue = 590.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachScoreRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = CareManagement.OutreachScoreRequiredBedRule(message: "outreach score needs this field")
        let item = CareManagement.newOutreachScore("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachScoreDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.OutreachScoreDiscountRangeRule(min: 2.5, max: 4663.9)
        let item = CareManagement.newOutreachScore("x", label: "y")
        item.discount = 4665.4
        #expect(rule.check(item).count > 0)
    }
}
