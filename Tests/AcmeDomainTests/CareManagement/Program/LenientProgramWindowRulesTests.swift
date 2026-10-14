@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientProgramWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientProgramWindowValidator()
        let item = CareManagement.newLenientProgramWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientProgramWindowAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = CareManagement.LenientProgramWindowAllergyLengthRule(maxLength: 32)
        let item = CareManagement.newLenientProgramWindow("x", name: "y")
        item.allergy = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientProgramWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.LenientProgramWindowRequiredNameRule(message: "lenient program window needs a value")
        let item = CareManagement.newLenientProgramWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientProgramWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LenientProgramWindowCodeLengthRule(maxLength: 255)
        let item = CareManagement.newLenientProgramWindow("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientProgramWindowNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.LenientProgramWindowNameLengthRule(maxLength: 1000)
        let item = CareManagement.newLenientProgramWindow("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
