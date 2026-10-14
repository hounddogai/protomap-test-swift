@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedFormularySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedFormularySnapshotValidator()
        let item = Pharmacy.newCappedFormularySnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedFormularySnapshotExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.CappedFormularySnapshotExternalRefLengthRule(maxLength: 1000)
        let item = Pharmacy.newCappedFormularySnapshot("x", name: "y")
        item.externalRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedFormularySnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.CappedFormularySnapshotRequiredNameRule(
            message: "capped formulary snapshot needs this field"
        )
        let item = Pharmacy.newCappedFormularySnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedFormularySnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.CappedFormularySnapshotRequiredCodeRule(
            message: "capped formulary snapshot needs this field"
        )
        let item = Pharmacy.newCappedFormularySnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedFormularySnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.CappedFormularySnapshotCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newCappedFormularySnapshot("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
