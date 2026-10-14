@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolEntryStore = Imaging.newMemoryCareProtocolEntryStore()
        let item = Imaging.newCareProtocolEntry("code-377", name: "name-80")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
