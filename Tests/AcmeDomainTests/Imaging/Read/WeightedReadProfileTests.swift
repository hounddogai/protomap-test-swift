@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadProfileTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newWeightedReadProfile("code-709", name: "name-535")
        #expect(item.status == Imaging.WeightedReadProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newWeightedReadProfile("code-709", name: "name-535")
        try item.moveTo(Imaging.WeightedReadProfileStatus.revoked)
        #expect(item.status == Imaging.WeightedReadProfileStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newWeightedReadProfile("code-709", name: "name-535")
        item.status = Imaging.WeightedReadProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedReadProfileStatus.requested) }
    }
}
