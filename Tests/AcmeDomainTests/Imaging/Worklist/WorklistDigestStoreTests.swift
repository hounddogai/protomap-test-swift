@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistDigestStore = Imaging.newMemoryWorklistDigestStore()
        let item = Imaging.newWorklistDigest("code-550", title: "title-82")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
