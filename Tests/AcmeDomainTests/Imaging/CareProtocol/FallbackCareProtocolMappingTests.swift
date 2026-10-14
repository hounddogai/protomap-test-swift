@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolMappingTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newFallbackCareProtocolMapping("code-979", name: "name-813")
        #expect(item.status == Imaging.FallbackCareProtocolMappingStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newFallbackCareProtocolMapping("code-979", name: "name-813")
        try item.moveTo(Imaging.FallbackCareProtocolMappingStatus.expired)
        #expect(item.status == Imaging.FallbackCareProtocolMappingStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newFallbackCareProtocolMapping("code-979", name: "name-813")
        item.status = Imaging.FallbackCareProtocolMappingStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackCareProtocolMappingStatus.requested) }
    }
}
