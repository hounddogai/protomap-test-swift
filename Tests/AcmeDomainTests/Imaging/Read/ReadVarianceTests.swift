@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadVarianceTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newReadVariance("code-980", name: "name-336")
        #expect(item.status == Imaging.ReadVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newReadVariance("code-980", name: "name-336")
        try item.moveTo(Imaging.ReadVarianceStatus.published)
        #expect(item.status == Imaging.ReadVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newReadVariance("code-980", name: "name-336")
        item.status = Imaging.ReadVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadVarianceStatus.created) }
    }
}
