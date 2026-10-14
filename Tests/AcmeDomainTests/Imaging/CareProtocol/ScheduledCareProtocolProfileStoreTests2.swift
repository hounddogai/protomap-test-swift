@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledCareProtocolProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledCareProtocolProfileStore = Imaging.newMemoryScheduledCareProtocolProfileStore()
        let item = Imaging.newScheduledCareProtocolProfile("code-518", name: "name-222")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
