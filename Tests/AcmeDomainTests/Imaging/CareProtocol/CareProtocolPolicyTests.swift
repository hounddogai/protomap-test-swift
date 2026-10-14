@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolPolicyTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCareProtocolPolicy("code-650", name: "name-903")
        #expect(item.status == Imaging.CareProtocolPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Imaging.newCareProtocolPolicy("code-650", name: "name-903")
        try item.moveTo(Imaging.CareProtocolPolicyStatus.closed)
        #expect(item.status == Imaging.CareProtocolPolicyStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCareProtocolPolicy("code-650", name: "name-903")
        item.status = Imaging.CareProtocolPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolPolicyStatus.draft) }
    }
}
