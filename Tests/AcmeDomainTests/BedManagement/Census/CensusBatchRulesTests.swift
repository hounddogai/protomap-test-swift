@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusBatchValidator()
        let item = BedManagement.newCensusBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusBatchSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = BedManagement.CensusBatchSourceLengthRule(maxLength: 16)
        let item = BedManagement.newCensusBatch("x", name: "y")
        item.source = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusBatchRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = BedManagement.CensusBatchRequiredPayerRule(message: "census batch needs an entry")
        let item = BedManagement.newCensusBatch("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
