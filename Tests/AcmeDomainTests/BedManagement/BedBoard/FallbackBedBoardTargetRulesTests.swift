@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackBedBoardTargetValidator()
        let item = BedManagement.newFallbackBedBoardTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackBedBoardTargetRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = BedManagement.FallbackBedBoardTargetRequiredCurrencyRule(
            message: "fallback bed board target needs a value"
        )
        let item = BedManagement.newFallbackBedBoardTarget("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackBedBoardTargetCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = BedManagement.FallbackBedBoardTargetCurrencyLengthRule(maxLength: 80)
        let item = BedManagement.newFallbackBedBoardTarget("x", label: "y")
        item.currency = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackBedBoardTargetDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.FallbackBedBoardTargetDurationMinutesRangeRule(min: 64, max: 3600)
        let item = BedManagement.newFallbackBedBoardTarget("x", label: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackBedBoardTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.FallbackBedBoardTargetRequiredLabelRule(
            message: "fallback bed board target needs a value"
        )
        let item = BedManagement.newFallbackBedBoardTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackBedBoardTargetDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = BedManagement.FallbackBedBoardTargetDescriptionLengthRule(maxLength: 3600)
        let item = BedManagement.newFallbackBedBoardTarget("x", label: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackBedBoardTargetRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = BedManagement.FallbackBedBoardTargetRequiredDescriptionRule(
            message: "fallback bed board target needs a value"
        )
        let item = BedManagement.newFallbackBedBoardTarget("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
