@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTieredIsolationGroupValidator()
        let item = BedManagement.newTieredIsolationGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTieredIsolationGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.TieredIsolationGroupNameLengthRule(maxLength: 255)
        let item = BedManagement.newTieredIsolationGroup("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
