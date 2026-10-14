@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolWindowTests {
    @Test func startsInNew() throws {
        let item = Imaging.newRollingCareProtocolWindow("code-394", title: "title-636")
        #expect(item.status == Imaging.RollingCareProtocolWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Imaging.newRollingCareProtocolWindow("code-394", title: "title-636")
        try item.moveTo(Imaging.RollingCareProtocolWindowStatus.failed)
        #expect(item.status == Imaging.RollingCareProtocolWindowStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newRollingCareProtocolWindow("code-394", title: "title-636")
        item.status = Imaging.RollingCareProtocolWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingCareProtocolWindowStatus.new) }
    }
}
