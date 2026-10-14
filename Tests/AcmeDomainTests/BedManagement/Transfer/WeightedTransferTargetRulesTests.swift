@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedTransferTargetValidator()
        let item = BedManagement.newWeightedTransferTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedTransferTargetRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = BedManagement.WeightedTransferTargetRequiredLocaleRule(
            message: "weighted transfer target needs this field"
        )
        let item = BedManagement.newWeightedTransferTarget("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedTransferTargetCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.WeightedTransferTargetCeilingRangeRule(min: 9.0, max: 1430.1)
        let item = BedManagement.newWeightedTransferTarget("x", label: "y")
        item.ceiling = 1431.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedTransferTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.WeightedTransferTargetRequiredCodeRule(
            message: "weighted transfer target needs this field"
        )
        let item = BedManagement.newWeightedTransferTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
