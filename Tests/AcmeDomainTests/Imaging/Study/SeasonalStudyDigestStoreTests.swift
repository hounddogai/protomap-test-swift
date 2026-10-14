@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalStudyDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalStudyDigestStore = Imaging.newMemorySeasonalStudyDigestStore()
        let item = Imaging.newSeasonalStudyDigest("code-121", label: "label-770")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
