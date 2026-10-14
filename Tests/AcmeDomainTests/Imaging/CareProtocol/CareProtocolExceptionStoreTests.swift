@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolExceptionStore = Imaging.newMemoryCareProtocolExceptionStore()
        let item = Imaging.newCareProtocolException("code-208", name: "name-627")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
