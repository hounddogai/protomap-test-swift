@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientCredentialVarianceTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newLenientCredentialVariance("code-126", label: "label-305")
        #expect(item.status == Staffing.LenientCredentialVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newLenientCredentialVariance("code-126", label: "label-305")
        try item.moveTo(Staffing.LenientCredentialVarianceStatus.resolved)
        #expect(item.status == Staffing.LenientCredentialVarianceStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newLenientCredentialVariance("code-126", label: "label-305")
        item.status = Staffing.LenientCredentialVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientCredentialVarianceStatus.`open`) }
    }
}
