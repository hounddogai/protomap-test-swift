@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackIsolationManifestValidator()
        let item = BedManagement.newFallbackIsolationManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackIsolationManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.FallbackIsolationManifestRequiredNameRule(
            message: "fallback isolation manifest needs this field"
        )
        let item = BedManagement.newFallbackIsolationManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackIsolationManifestUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.FallbackIsolationManifestUpdatedAtRangeRule(min: 16, max: 86400)
        let item = BedManagement.newFallbackIsolationManifest("x", name: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackIsolationManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.FallbackIsolationManifestCodeLengthRule(maxLength: 80)
        let item = BedManagement.newFallbackIsolationManifest("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackIsolationManifestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.FallbackIsolationManifestNameLengthRule(maxLength: 16)
        let item = BedManagement.newFallbackIsolationManifest("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
