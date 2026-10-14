@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadMappingTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newLenientReadMapping("code-845", name: "name-300")
        #expect(item.status == Imaging.LenientReadMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newLenientReadMapping("code-845", name: "name-300")
        try item.moveTo(Imaging.LenientReadMappingStatus.approved)
        #expect(item.status == Imaging.LenientReadMappingStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newLenientReadMapping("code-845", name: "name-300")
        item.status = Imaging.LenientReadMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientReadMappingStatus.proposed) }
    }
}
