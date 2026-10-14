@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAssignmentTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newModalityAssignment("code-939", name: "name-102")
        #expect(item.status == Imaging.ModalityAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newModalityAssignment("code-939", name: "name-102")
        try item.moveTo(Imaging.ModalityAssignmentStatus.validated)
        #expect(item.status == Imaging.ModalityAssignmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newModalityAssignment("code-939", name: "name-102")
        item.status = Imaging.ModalityAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityAssignmentStatus.created) }
    }
}
