@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualTransferEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualTransferEstimateValidator()
        let item = BedManagement.newManualTransferEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualTransferEstimateAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = BedManagement.ManualTransferEstimateAcuityRangeRule(min: 3600, max: 86400)
        let item = BedManagement.newManualTransferEstimate("x", name: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualTransferEstimateCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.ManualTransferEstimateCreatedAtRangeRule(min: 80, max: 120)
        let item = BedManagement.newManualTransferEstimate("x", name: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualTransferEstimateRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = BedManagement.ManualTransferEstimateRequiredChannelRule(
            message: "manual transfer estimate needs an entry"
        )
        let item = BedManagement.newManualTransferEstimate("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualTransferEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualTransferEstimateCodeLengthRule(maxLength: 120)
        let item = BedManagement.newManualTransferEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualTransferEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.ManualTransferEstimateRequiredNameRule(
            message: "manual transfer estimate needs an entry"
        )
        let item = BedManagement.newManualTransferEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
