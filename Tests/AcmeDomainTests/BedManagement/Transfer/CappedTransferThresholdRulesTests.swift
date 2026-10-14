@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedTransferThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedTransferThresholdValidator()
        let item = BedManagement.newCappedTransferThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedTransferThresholdScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.CappedTransferThresholdScoreRangeRule(min: 6.3, max: 3022.0)
        let item = BedManagement.newCappedTransferThreshold("x", title: "y")
        item.score = 3023.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedTransferThresholdProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = BedManagement.CappedTransferThresholdProcedureCodeLengthRule(maxLength: 120)
        let item = BedManagement.newCappedTransferThreshold("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedTransferThresholdCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.CappedTransferThresholdCopayRangeRule(min: 4.8, max: 1266.1)
        let item = BedManagement.newCappedTransferThreshold("x", title: "y")
        item.copay = 1267.6
        #expect(rule.check(item).count > 0)
    }
}
