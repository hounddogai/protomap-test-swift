@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalModalityClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalModalityClaimStore = Imaging.newMemoryRegionalModalityClaimStore()
        let item = Imaging.newRegionalModalityClaim("code-647", label: "label-847")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
