@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadMappingTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newReadMapping("code-925", name: "name-276")
        #expect(item.status == Imaging.ReadMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newReadMapping("code-925", name: "name-276")
        try item.moveTo(Imaging.ReadMappingStatus.cancelled)
        #expect(item.status == Imaging.ReadMappingStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newReadMapping("code-925", name: "name-276")
        item.status = Imaging.ReadMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadMappingStatus.planned) }
    }
}
