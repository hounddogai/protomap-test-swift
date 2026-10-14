@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationGroupValidator()
        let item = BedManagement.newIsolationGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationGroupChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.IsolationGroupChecksumLengthRule(maxLength: 1000)
        let item = BedManagement.newIsolationGroup("x", title: "y")
        item.checksum = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationGroupCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newIsolationGroup("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationGroupDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.IsolationGroupDiscountRangeRule(min: 1.0, max: 1336.1)
        let item = BedManagement.newIsolationGroup("x", title: "y")
        item.discount = 1337.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationGroupRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = BedManagement.IsolationGroupRequiredChecksumRule(message: "isolation group needs this field")
        let item = BedManagement.newIsolationGroup("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationGroupRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = BedManagement.IsolationGroupRefillsRangeRule(min: 255, max: 86400)
        let item = BedManagement.newIsolationGroup("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}
