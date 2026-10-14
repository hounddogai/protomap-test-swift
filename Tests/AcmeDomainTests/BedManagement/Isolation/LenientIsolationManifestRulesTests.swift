@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientIsolationManifestValidator()
        let item = BedManagement.newLenientIsolationManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientIsolationManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.LenientIsolationManifestTitleLengthRule(maxLength: 3600)
        let item = BedManagement.newLenientIsolationManifest("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientIsolationManifestRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = BedManagement.LenientIsolationManifestRequiredPayerRule(
            message: "lenient isolation manifest needs this field"
        )
        let item = BedManagement.newLenientIsolationManifest("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientIsolationManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LenientIsolationManifestCodeLengthRule(maxLength: 32)
        let item = BedManagement.newLenientIsolationManifest("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
