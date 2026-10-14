@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionProfileTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newSubstitutionProfile("code-948", title: "title-799")
        #expect(item.status == Pharmacy.SubstitutionProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newSubstitutionProfile("code-948", title: "title-799")
        try item.moveTo(Pharmacy.SubstitutionProfileStatus.draining)
        #expect(item.status == Pharmacy.SubstitutionProfileStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newSubstitutionProfile("code-948", title: "title-799")
        item.status = Pharmacy.SubstitutionProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionProfileStatus.idle) }
    }
}
