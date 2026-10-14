@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityAgreementTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newGlobalPriorityAgreement("code-89", name: "name-635")
        #expect(item.status == Imaging.GlobalPriorityAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newGlobalPriorityAgreement("code-89", name: "name-635")
        try item.moveTo(Imaging.GlobalPriorityAgreementStatus.inProgress)
        #expect(item.status == Imaging.GlobalPriorityAgreementStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newGlobalPriorityAgreement("code-89", name: "name-635")
        item.status = Imaging.GlobalPriorityAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalPriorityAgreementStatus.planned) }
    }
}
