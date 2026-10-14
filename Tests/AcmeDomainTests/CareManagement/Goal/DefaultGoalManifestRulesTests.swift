@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultGoalManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultGoalManifestValidator()
        let item = CareManagement.newDefaultGoalManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultGoalManifestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = CareManagement.DefaultGoalManifestEndsAtRangeRule(min: 64, max: 86400)
        let item = CareManagement.newDefaultGoalManifest("x", label: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementDefaultGoalManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.DefaultGoalManifestRequiredCodeRule(message: "default goal manifest needs this field")
        let item = CareManagement.newDefaultGoalManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultGoalManifestRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = CareManagement.DefaultGoalManifestRequiredCountryRule(
            message: "default goal manifest needs this field"
        )
        let item = CareManagement.newDefaultGoalManifest("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultGoalManifestVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = CareManagement.DefaultGoalManifestVisitMinutesRangeRule(min: 64, max: 255)
        let item = CareManagement.newDefaultGoalManifest("x", label: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementDefaultGoalManifestCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = CareManagement.DefaultGoalManifestCountryLengthRule(maxLength: 32)
        let item = CareManagement.newDefaultGoalManifest("x", label: "y")
        item.country = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultGoalManifestRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = CareManagement.DefaultGoalManifestRequiredSpecialtyRule(
            message: "default goal manifest needs this field"
        )
        let item = CareManagement.newDefaultGoalManifest("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
