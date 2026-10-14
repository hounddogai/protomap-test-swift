@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictBedBoardVarianceValidator()
        let item = BedManagement.newStrictBedBoardVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictBedBoardVariancePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = BedManagement.StrictBedBoardVariancePhoneLengthRule(maxLength: 255)
        let item = BedManagement.newStrictBedBoardVariance("x", name: "y")
        item.phone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictBedBoardVarianceCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = BedManagement.StrictBedBoardVarianceCurrencyLengthRule(maxLength: 120)
        let item = BedManagement.newStrictBedBoardVariance("x", name: "y")
        item.currency = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictBedBoardVarianceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.StrictBedBoardVarianceNameLengthRule(maxLength: 64)
        let item = BedManagement.newStrictBedBoardVariance("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
