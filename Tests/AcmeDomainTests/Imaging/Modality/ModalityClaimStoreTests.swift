@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityClaimStore = Imaging.newMemoryModalityClaimStore()
        let item = Imaging.newModalityClaim("code-349", label: "label-827")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
