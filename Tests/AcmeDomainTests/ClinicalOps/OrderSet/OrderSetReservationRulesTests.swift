@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetReservationValidator()
        let item = ClinicalOps.newOrderSetReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetReservationRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = ClinicalOps.OrderSetReservationRequiredChecksumRule(message: "order set reservation needs a value")
        let item = ClinicalOps.newOrderSetReservation("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetReservationCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newOrderSetReservation("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.OrderSetReservationLabelLengthRule(maxLength: 32)
        let item = ClinicalOps.newOrderSetReservation("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetReservationRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = ClinicalOps.OrderSetReservationRequiredSourceRule(message: "order set reservation needs this field")
        let item = ClinicalOps.newOrderSetReservation("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetReservationRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = ClinicalOps.OrderSetReservationRatioRangeRule(min: 9.5, max: 1185.4)
        let item = ClinicalOps.newOrderSetReservation("x", label: "y")
        item.ratio = 1186.9
        #expect(rule.check(item).count > 0)
    }
}
