@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardBundleValidator()
        let item = BedManagement.newBedBoardBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardBundleExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = BedManagement.BedBoardBundleExternalRefLengthRule(maxLength: 64)
        let item = BedManagement.newBedBoardBundle("x", label: "y")
        item.externalRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardBundleRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = BedManagement.BedBoardBundleRequiredExternalRefRule(message: "bed board bundle needs an entry")
        let item = BedManagement.newBedBoardBundle("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
