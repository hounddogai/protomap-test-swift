@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingCareProtocolExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingCareProtocolExceptionStore = Imaging.newMemoryPendingCareProtocolExceptionStore()
        let item = Imaging.newPendingCareProtocolException("code-663", name: "name-668")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
