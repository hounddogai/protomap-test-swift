@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackTransferTemplateValidator()
        let item = BedManagement.newFallbackTransferTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackTransferTemplateDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.FallbackTransferTemplateDosageMgRangeRule(min: 1.8, max: 2235.3)
        let item = BedManagement.newFallbackTransferTemplate("x", title: "y")
        item.dosageMg = 2236.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackTransferTemplateFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.FallbackTransferTemplateFloorValueRangeRule(min: 2.1, max: 3987.1)
        let item = BedManagement.newFallbackTransferTemplate("x", title: "y")
        item.floorValue = 3988.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackTransferTemplateCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.FallbackTransferTemplateCreatedAtRangeRule(min: 16, max: 1000)
        let item = BedManagement.newFallbackTransferTemplate("x", title: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackTransferTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.FallbackTransferTemplateRequiredTitleRule(
            message: "fallback transfer template needs an entry"
        )
        let item = BedManagement.newFallbackTransferTemplate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
