@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledCareProtocolExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledCareProtocolExceptionStore = Imaging.newMemoryScheduledCareProtocolExceptionStore()
        let item = Imaging.newScheduledCareProtocolException("code-784", title: "title-404")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
